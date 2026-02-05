import http.server
import socketserver
import urllib.request
import ssl
import json
import os

PORT = 9201
TARGET = "https://wazuh.vip:9200"

# Paths to certificates inside the container
CA_CERT = "/etc/ssl/root-ca.pem"
CLIENT_CERT = "/etc/ssl/filebeat.pem"
CLIENT_KEY = "/etc/ssl/filebeat.key"

# Create a custom SSL context
ctx = ssl.create_default_context(cafile=CA_CERT)
if os.path.exists(CLIENT_CERT) and os.path.exists(CLIENT_KEY):
    ctx.load_cert_chain(certfile=CLIENT_CERT, keyfile=CLIENT_KEY)
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

class OpenSearchProxy(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path.startswith("/_license"):
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            response = {
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
            self.wfile.write(json.dumps(response).encode())
            return
        if self.path.startswith("/_xpack"):
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(b'{"features":{}}')
            return
        self.proxy_request("GET")

    def do_POST(self):
        self.proxy_request("POST")

    def do_PUT(self):
        self.proxy_request("PUT")

    def do_HEAD(self):
        self.proxy_request("HEAD")

    def proxy_request(self, method):
        url = TARGET + self.path
        headers = {k: v for k, v in self.headers.items() if k.lower() not in ["host", "connection"]}
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length) if content_length > 0 else None
        req = urllib.request.Request(url, data=body, headers=headers, method=method)
        try:
            with urllib.request.urlopen(req, context=ctx) as r:
                self.send_response(r.status)
                for k, v in r.getheaders():
                    if k.lower() not in ["transfer-encoding", "connection", "content-length"]:
                        self.send_header(k, v)
                self.end_headers()
                self.wfile.write(r.read())
        except urllib.error.HTTPError as e:
            self.send_response(e.code)
            for k, v in e.headers.items():
                self.send_header(k, v)
            self.end_headers()
            self.wfile.write(e.read())
        except Exception as e:
            self.send_response(500)
            self.end_headers()
            self.wfile.write(str(e).encode())

with socketserver.ThreadingTCPServer(("0.0.0.0", PORT), OpenSearchProxy) as httpd:
    httpd.serve_forever()
