import os
import logging
import ssl
import yaml
import asyncio
import time
from typing import Optional, List, Dict, Any
from fastapi import FastAPI, Request, Response, BackgroundTasks
from fastapi.responses import JSONResponse
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
import httpx
from watchfiles import awatch

# Logging Configuration
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger("wazuh-proxy")

CONFIG_PATH = os.getenv("CONFIG_PATH", "config.yaml")

class ConfigManager:
    def __init__(self, config_path: str):
        self.config_path = config_path
        self.config = {}
        self.ssl_context = None
        self.load_config()

    def load_config(self):
        try:
            with open(self.config_path, 'r') as f:
                self.config = yaml.safe_load(f)
            logger.info(f"Loaded configuration from {self.config_path}")
            self._setup_ssl()
        except Exception as e:
            logger.error(f"Failed to load configuration: {e}")

    def _setup_ssl(self):
        mtls = self.config.get("security", {}).get("mtls", {})
        ca_cert = mtls.get("ca_cert")
        client_cert = mtls.get("client_cert")
        client_key = mtls.get("client_key")

        if not ca_cert:
            logger.warning("No CA cert found in config, using default cert verification.")
            self.ssl_context = ssl.create_default_context()
        else:
            self.ssl_context = ssl.create_default_context(cafile=ca_cert)
            if client_cert and client_key and os.path.exists(client_cert) and os.path.exists(client_key):
                self.ssl_context.load_cert_chain(certfile=client_cert, keyfile=client_key)
                logger.info("mTLS client certificate loaded.")
            
        self.ssl_context.check_hostname = True
        self.ssl_context.verify_mode = ssl.CERT_REQUIRED

    async def watch_config(self):
        async for changes in awatch(self.config_path):
            logger.info("Configuration change detected, reloading...")
            self.load_config()

class UpstreamManager:
    def __init__(self, config_manager: ConfigManager):
        self.config_manager = config_manager
        self.targets = []
        self.current_index = 0
        self.health_status = {}
        self._update_targets()

    def _update_targets(self):
        self.targets = self.config_manager.config.get("upstream", {}).get("targets", [])
        for target in self.targets:
            if target['url'] not in self.health_status:
                self.health_status[target['url']] = True

    def get_next_target(self) -> Optional[str]:
        self._update_targets() # Ensure we have latest targets
        healthy_targets = [t for t in self.targets if self.health_status.get(t['url'], True)]
        
        if not healthy_targets:
            logger.error("No healthy upstream targets available!")
            return None
        
        # Simple Round Robin for now
        target = healthy_targets[self.current_index % len(healthy_targets)]
        self.current_index += 1
        return target['url']

    def mark_unhealthy(self, url: str):
        self.health_status[url] = False
        logger.warning(f"Target marked as UNHEALTHY: {url}")

    async def health_checker(self):
        while True:
            interval = self.config_manager.config.get("upstream", {}).get("health_check_interval", 30)
            await asyncio.sleep(interval)
            
            for target in self.targets:
                url = target['url']
                try:
                    async with httpx.AsyncClient(verify=self.config_manager.ssl_context, timeout=5.0) as client:
                        resp = await client.get(url)
                        if resp.status_code == 200:
                            if not self.health_status[url]:
                                logger.info(f"Target recovered (HEALTHY): {url}")
                            self.health_status[url] = True
                        else:
                            self.mark_unhealthy(url)
                except Exception:
                    self.mark_unhealthy(url)

class PolicyEngine:
    def __init__(self, config_manager: ConfigManager):
        self.config_manager = config_manager

    def evaluate(self, method: str, path: str, body_size: int = 0) -> Optional[str]:
        policies = self.config_manager.config.get("security", {}).get("policies", [])
        
        # Default block for dangerous methods
        if method == "DELETE":
            return "DELETE method is explicitly forbidden."

        for policy in policies:
            target_path = policy.get("path")
            if target_path == "*" or path.startswith(target_path):
                # Check blocked methods
                if method in policy.get("blocked_methods", []):
                    return f"Method {method} is blocked for path {path}"
                
                # Check allowed methods (if defined)
                allowed = policy.get("allowed_methods")
                if allowed and method not in allowed:
                    return f"Method {method} is not in allowed list for path {path}"
                
                # Check max size
                max_size_mb = policy.get("max_size_mb")
                if max_size_mb and body_size > (max_size_mb * 1024 * 1024):
                    return f"Payload size exceeds limit of {max_size_mb}MB"
        
        return None

# Initialize Core Managers
config_manager = ConfigManager(CONFIG_PATH)
upstream_manager = UpstreamManager(config_manager)
policy_engine = PolicyEngine(config_manager)

# Setup FastAPI
limiter = Limiter(key_func=get_remote_address)
app = FastAPI(title="Wazuh-Proxy Advanced", version="3.0.0")
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

@app.on_event("startup")
async def startup_event():
    asyncio.create_task(config_manager.watch_config())
    asyncio.create_task(upstream_manager.health_checker())

@app.middleware("http")
async def security_middleware(request: Request, call_next):
    body = await request.body()
    error = policy_engine.evaluate(request.method, request.url.path, len(body))
    if error:
        logger.warning(f"Policy Block: {error} from {request.client.host}")
        return JSONResponse(status_code=403, content={"error": error})
    
    # Store body in request state so it can be reused in proxy_request
    request.state.body = body
    response = await call_next(request)
    return response

@app.get("/stats")
async def get_stats():
    return {
        "status": "online",
        "upstreams": upstream_manager.health_status,
        "config_path": CONFIG_PATH,
        "version": "3.0.0"
    }

@app.get("/_license")
async def mock_license():
    return {
        "license": {
            "status": "active",
            "type": "basic",
            "uid": "wazuh-proxy-v3",
            "issue_date_in_millis": int(time.time() * 1000),
            "expiry_date_in_millis": 4070908800000,
            "issued_to": "Enterprise Wazuh",
            "issuer": "Wazuh-Proxy-Refactored"
        }
    }

@app.api_route("/{path_name:path}", methods=["GET", "POST", "PUT", "HEAD"])
@limiter.limit("1000/minute")
async def proxy_request(path_name: str, request: Request, response: Response):
    target_url = upstream_manager.get_next_target()
    if not target_url:
        return JSONResponse(status_code=503, content={"error": "All upstreams are unavailable"})

    url = f"{target_url}/{path_name}"
    headers = {k: v for k, v in request.headers.items() if k.lower() not in ["host", "content-length", "connection"]}
    
    try:
        content = getattr(request.state, "body", b"")
        timeout_val = config_manager.config.get("upstream", {}).get("timeout", 30.0)
        timeout = httpx.Timeout(timeout_val)
        
        async with httpx.AsyncClient(verify=config_manager.ssl_context, timeout=timeout) as client:
            proxy_req = client.build_request(request.method, url, headers=headers, content=content)
            upstream_response = await client.send(proxy_req)
            
            response.status_code = upstream_response.status_code
            for k, v in upstream_response.headers.items():
                if k.lower() not in ["transfer-encoding", "connection", "content-length"]:
                     response.headers[k] = v
            
            return upstream_response.content
            
    except httpx.RequestError as exc:
        logger.error(f"Upstream Error ({url}): {exc}")
        upstream_manager.mark_unhealthy(target_url)
        return JSONResponse(status_code=502, content={"error": "Failed to connect to upstream indexer"})
    except Exception as exc:
        logger.error(f"Internal proxy error: {exc}")
        return JSONResponse(status_code=500, content={"error": "Internal Proxy Error"})
