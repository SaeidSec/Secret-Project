import os
import logging
import ssl
from typing import Optional

from fastapi import FastAPI, Request, Response
from fastapi.responses import JSONResponse
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
import httpx

# Logging Configuration
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger("wazuh-proxy")

# Environment Variables
TARGET_URL = os.getenv("TARGET_URL", "https://wazuh.vip:9200")
CA_CERT = os.getenv("CA_CERT", "/etc/ssl/root-ca.pem")
CLIENT_CERT = os.getenv("CLIENT_CERT", "/etc/ssl/filebeat.pem")
CLIENT_KEY = os.getenv("CLIENT_KEY", "/etc/ssl/filebeat.key")

# Setup Limiter
limiter = Limiter(key_func=get_remote_address)
app = FastAPI(title="Wazuh-OpenSearch Compatibility Proxy", version="2.0.0")
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# Create SSL Context for Upstream Connection
# This context is used when the PROXY talks to OpenSearch/Indexer
ssl_context = ssl.create_default_context(cafile=CA_CERT)
if os.path.exists(CLIENT_CERT) and os.path.exists(CLIENT_KEY):
    ssl_context.load_cert_chain(certfile=CLIENT_CERT, keyfile=CLIENT_KEY)
# We keep verification enabled for upstream!
ssl_context.check_hostname = True
ssl_context.verify_mode = ssl.CERT_REQUIRED

@app.middleware("http")
async def filter_requests(request: Request, call_next):
    # Method Blocking
    if request.method == "DELETE":
        logger.warning(f"Blocked DELETE request from {request.client.host}")
        return JSONResponse(status_code=403, content={"error": "DELETE method is not allowed"})
    
    # Path Blocking for destructive cluster operations
    path = request.url.path
    if path.startswith("/_cluster") and request.method not in ["GET", "HEAD"]:
         # Only allow GET/HEAD on _cluster, block settings changes
        logger.warning(f"Blocked destructive _cluster request from {request.client.host} to {path}")
        return JSONResponse(status_code=403, content={"error": "Destructive cluster operations are not allowed"})
    
    response = await call_next(request)
    return response

@app.get("/_license")
async def mock_license():
    logger.info("Serving mock license")
    return {
        "license": {
            "status": "active",
            "type": "basic",
            "uid": "wazuh-uid",
            "issue_date": "2026-01-01T00:00:00.000Z",
            "issue_date_in_millis": 1767225600000,
            "expiry_date": "2099-01-01T00:00:00.000Z",
            "expiry_date_in_millis": 4070908800000,
            "max_nodes": 1000,
            "issued_to": "wazuh",
            "issuer": "elasticsearch",
            "start_date_in_millis": -1
        }
    }

@app.get("/_xpack")
async def mock_xpack():
    logger.info("Serving mock xpack")
    return {"features": {}}

@app.get("/")
async def health_check():
    return {"status": "ok", "proxy": "wazuh-proxy"}

@app.api_route("/{path_name:path}", methods=["GET", "POST", "PUT", "HEAD"])
@limiter.limit("500/minute") # Rate limiting
async def proxy_request(path_name: str, request: Request, response: Response):
    url = f"{TARGET_URL}/{path_name}"
    
    # Filter headers to avoid conflicts
    headers = {k: v for k, v in request.headers.items() if k.lower() not in ["host", "content-length", "connection"]}
    
    try:
        content = await request.body()
        
        async with httpx.AsyncClient(verify=ssl_context, timeout=30.0) as client:
            proxy_req = client.build_request(
                request.method,
                url,
                headers=headers,
                content=content
            )
            upstream_response = await client.send(proxy_req)
            
            response.status_code = upstream_response.status_code
            for k, v in upstream_response.headers.items():
                if k.lower() not in ["transfer-encoding", "connection", "content-length"]:
                     response.headers[k] = v
            
            return upstream_response.content
            
    except httpx.RequestError as exc:
        logger.error(f"Proxy error connecting to {url}: {exc}")
        return JSONResponse(status_code=502, content={"error": f"Proxy error upstream: {str(exc)}"})
    except Exception as exc:
        logger.error(f"Internal proxy error: {exc}")
        return JSONResponse(status_code=500, content={"error": f"Internal Error: {str(exc)}"})
