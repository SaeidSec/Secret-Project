#!/bin/bash
# 🚀 Universal Wazuh SIEM Deployment Fixer
# Fixes: "Not a directory" mount errors, SSL Certificate issues, and "No template found" errors.

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔍 Starting Universal Wazuh Fixer...${NC}"

# 1. Path Safety and Root Check
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ Warning: This script needs to check system settings and manage Docker.${NC}"
   echo "Please run with: sudo bash bootstrap.sh"
   exit 1
fi

# 2. System Settings Check (vm.max_map_count)
echo -e "${BLUE}⚙️ Checking System Settings...${NC}"
VMM_COUNT=$(sysctl -n vm.max_map_count)
if [ "$VMM_COUNT" -lt 262144 ]; then
    echo "🔧 Increasing vm.max_map_count to 262144..."
    sysctl -w vm.max_map_count=262144
    echo "vm.max_map_count=262144" | tee -a /etc/sysctl.conf
else
    echo "✅ vm.max_map_count is already sufficient ($VMM_COUNT)"
fi

# 3. Environment File Preparation
if [ ! -f ".env" ]; then
    echo "📄 Creating .env file from .env.example..."
    cp .env.example .env
    echo "✅ .env file created. Please update it if you need custom passwords."
else
    echo "✅ .env file already exists."
fi

# 4. Stop services
echo -e "${BLUE}🛑 Stopping services and cleaning up...${NC}"
docker compose down --remove-orphans > /dev/null 2>&1 || true

# 5. Fix "Not a Directory" Mount Issues
echo -e "${BLUE}🔧 Cleaning invalid bind-mount folders...${NC}"
CERT_DIR="config/wazuh_indexer_ssl_certs"
if [ -d "$CERT_DIR" ]; then
    # Docker creates directories if files are missing. We delete folders ending in .pem or .key
    find "$CERT_DIR" -mindepth 1 -maxdepth 1 -type d \( -name "*.pem" -o -name "*.key" \) -exec rm -rf {} +
    echo "✅ Cleaned up $CERT_DIR"
else
    mkdir -p "$CERT_DIR"
fi

# 6. Generate Certificates
echo -e "${BLUE}🔐 Generating SSL Certificates...${NC}"
docker compose -f generate-indexer-certs.yml run --rm generator

# 7. Start the Stack
echo -e "${BLUE}🚀 Starting Wazuh Stack...${NC}"
docker compose up -d

# 8. Wait for Indexer & Load Template
echo -e "${BLUE}⏳ Waiting for Wazuh Indexer to be healthy (this takes 1-2 minutes)...${NC}"
MAX_RETRIES=30
RETRY_COUNT=0
HEALTHY=false

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -k -u admin:SecretPassword https://localhost:9200/_cluster/health?pretty 2>/dev/null | grep -q '"status" : "green"\|"status" : "yellow"'; then
        echo -e "${GREEN}✅ Indexer is UP!${NC}"
        HEALTHY=true
        break
    fi
    echo -n "."
    sleep 10
    RETRY_COUNT=$((RETRY_COUNT+1))
done

if [ "$HEALTHY" = true ]; then
    echo -e "${BLUE}📤 Forcing Wazuh Index Template upload...${NC}"
    MASTER_CONTAINER=$(docker ps --format '{{.Names}}' | grep "wazuh.master" | head -n 1)
    if [ -n "$MASTER_CONTAINER" ]; then
        docker exec "$MASTER_CONTAINER" filebeat setup --index-management \
            -E setup.template.overwrite=true \
            -E output.elasticsearch.ssl.verification_mode=none
        echo -e "${GREEN}✅ Index Template uploaded successfully!${NC}"
    else
        echo -e "${RED}❌ Error: Master container not found for template upload.${NC}"
    fi
else
    echo -e "${RED}❌ Warning: Indexer timeout. You might need to run the template fix manually later.${NC}"
fi

echo ""
echo -e "${GREEN}🎉 ALL FIXED! BRO GO FAST! refresh your dashboard now.${NC}"
echo -e "${BLUE}Dashboard: https://172.25.0.222${NC}"
echo ""
