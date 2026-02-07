FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Expose the port
EXPOSE 9201

# Container health check using the new /stats endpoint
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:9201/stats || exit 1

# Run the application with Uvicorn
# SSL configuration handles the incoming connection (Agent -> Proxy)
# Parameters are passed to handle mTLS at the entry point.
CMD ["uvicorn", "main:app", \
     "--host", "0.0.0.0", \
     "--port", "9201", \
     "--ssl-keyfile", "/etc/ssl/filebeat.key", \
     "--ssl-certfile", "/etc/ssl/filebeat.pem", \
     "--ssl-ca-certs", "/etc/ssl/root-ca.pem", \
     "--ssl-cert-reqs", "2"]
