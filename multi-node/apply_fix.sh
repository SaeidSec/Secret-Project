#!/bin/bash
# Apply Wazuh HA Fix
# Run this script with sudo

if [ "$EUID" -ne 0 ]
  then echo "Please run as root (sudo)"
  exit
fi

echo "Stopping Wazuh Stack..."
docker compose down

echo "Starting Wazuh Stack with HA Fix..."
docker compose up -d

echo "Waiting for stack to initialize..."
sleep 10

echo "Verifying IP assignments..."
LB1_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' multi-node-nginx-lb-1-1 2>/dev/null || echo "Not Found")
LB2_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' multi-node-nginx-lb-2-1 2>/dev/null || echo "Not Found")

echo "LB Node 1 IP: $LB1_IP (Expected: 172.25.0.10)"
echo "LB Node 2 IP: $LB2_IP (Expected: 172.25.0.11)"

if [[ "$LB1_IP" == "172.25.0.10" && "$LB2_IP" == "172.25.0.11" ]]; then
    echo "SUCCESS: Static IPs assigned correctly."
else
    echo "WARNING: IP assignment mismatch. Check docker-compose.yml."
fi

echo "Done. Please check 'docker logs keepalived-1' to verify UNICAST peering."
