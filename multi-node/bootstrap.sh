#!/bin/bash
# 🚀 Wazuh SIEM Bootstrap Script
# Helps fix the "not a directory" mount error on new installations.

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔍 Starting Wazuh Bootstrap Process...${NC}"

# 1. Check if we are in the multi-node directory
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}❌ Error: Please run this script from the 'multi-node' directory.${NC}"
    exit 1
fi

# 2. Stop any partially running containers
echo "🛑 Stopping any partially started services..."
docker compose down --remove-orphans > /dev/null 2>&1 || true

# 3. Clean up invalid directories in the certs folder
# Docker creates directories if files are missing during bind-mount
echo "🔧 Cleaning up invalid certificate directories..."
CERT_DIR="config/wazuh_indexer_ssl_certs"

if [ -d "$CERT_DIR" ]; then
    # Find any directory ending in .pem or .key and remove it
    find "$CERT_DIR" -mindepth 1 -maxdepth 1 -type d \( -name "*.pem" -o -name "*.key" \) -exec rm -rf {} +
    echo "✅ Cleaned up invalid folders in $CERT_DIR"
else
    mkdir -p "$CERT_DIR"
    echo "✅ Created missing cert directory: $CERT_DIR"
fi

# 4. Generate Certificates
echo "🔐 Generating SSL Certificates (this may take a minute)..."
docker compose -f generate-indexer-certs.yml run --rm generator

# 5. Final Verification
echo "🔬 Verifying certificates..."
if [ -f "$CERT_DIR/root-ca.pem" ]; then
    echo -e "${GREEN}✅ Success! Certificates generated correctly.${NC}"
else
    echo -e "${RED}❌ Error: Certificate generation failed.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 Bootstrap Complete! You can now start the stack with:${NC}"
echo "   docker compose up -d"
echo ""
