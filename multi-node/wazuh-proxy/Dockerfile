FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Expose the port (though Docker Compose handles mapping)
EXPOSE 9201

# Run the application with Uvicorn
# SSL configuration will be handled in main.py via Uvicorn programmatic execution 
# OR via command line arguments if we decided to pass them there.
# However, the plan says "Implement TLS/SSL Context with verification" in main.py usually implies 
# we might run it via python main.py or uvicorn with ssl flags.
# Let's stick to standard uvicorn command and handle SSL via arguments for simplicity and robustness.
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "9201", "--ssl-keyfile", "/etc/ssl/filebeat.key", "--ssl-certfile", "/etc/ssl/filebeat.pem", "--ssl-ca-certs", "/etc/ssl/root-ca.pem", "--ssl-cert-reqs", "2"]
