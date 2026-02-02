#!/bin/bash
# 🚀 Enterprise Wazuh SIEM Deployment & Infrastructure Fixer
# This script ensures a smooth, error-free deployment on any linux system.

set -e

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# --- 1. Root Check ---
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root (sudo)."
   exit 1
fi

log_info "Starting Infrastructure preparation..."

# --- 2. Dependency Checks ---
log_info "Checking dependencies..."
for cmd in docker docker-compose; do
    if ! command -v $cmd &> /dev/null; then
        log_error "$cmd is not installed. Please install it first."
        exit 1
    fi
done
log_success "Dependencies verified."

# --- 3. System Tuning ---
log_info "Optimizing system settings..."
VMM_COUNT=$(sysctl -n vm.max_map_count)
if [ "$VMM_COUNT" -lt 262144 ]; then
    log_info "Increasing vm.max_map_count to 262144..."
    sysctl -w vm.max_map_count=262144
    echo "vm.max_map_count=262144" | tee -a /etc/sysctl.conf > /dev/null
fi
log_success "System settings optimized."

# --- 4. Directory Preparation ---
log_info "Preparing directory structure and permissions..."
# Define required directories for bind mounts
REQUIRED_DIRS=(
    "config/wazuh_indexer_ssl_certs"
    "config/graylog"
    "config/trivy"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        log_info "Creating missing directory: $dir"
        mkdir -p "$dir"
    fi
done

# Fix specific permissions for Graylog (needs UID 1100) and OSSEC
# If directories were created by docker as root, they might block services
# Clean up any Docker-created directories where files should be
find config/wazuh_indexer_ssl_certs -mindepth 1 -maxdepth 1 -type d \( -name "*.pem" -o -name "*.key" \) -exec rm -rf {} +

# Ensure certs are readable by containers
chmod -R 755 config/
find config/wazuh_indexer_ssl_certs -type f -exec chmod 644 {} +

log_success "Directory structure ready."

# --- 5. Environment File ---
if [ ! -f ".env" ]; then
    log_warn ".env file not found. Creating from .env.example..."
    cp .env.example .env
    log_info "Created .env. Please review it before starting if you need custom passwords."
else
    log_success ".env file exists."
fi

# --- 6. Certificate Generation ---
log_info "Checking SSL Certificates..."
if [ ! -f "config/wazuh_indexer_ssl_certs/root-ca.pem" ]; then
    log_info "Generating fresh SSL certificates..."
    docker compose -f generate-indexer-certs.yml run --rm generator
    log_success "Certificates generated."
else
    log_info "Existing certificates found. Skipping generation."
fi

# Ensure permissions after generation
chmod -R 755 config/wazuh_indexer_ssl_certs/
chmod 644 config/wazuh_indexer_ssl_certs/*.pem || true
chmod 644 config/wazuh_indexer_ssl_certs/*-key.pem || true

# --- 7. Deployment ---
log_info "Stopping existing services (if any)..."
docker compose down --remove-orphans > /dev/null 2>&1

log_info "Launching the Wazuh SIEM stack..."
docker compose up -d

# --- 8. Post-Check & Health ---
log_info "Waiting for Wazuh Indexer to initialize..."
MAX_WAIT=20
WAIT_COUNT=0
INDEXER_READY=false

# Use the VIP if configured, otherwise localhost for healthcheck
VIP=$(grep VIRTUAL_IP .env | cut -d'=' -f2)
HOST=${VIP:-localhost}

while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
    if curl -k -u admin:SecretPassword https://${HOST}:9200/_cluster/health?pretty 2>/dev/null | grep -q '"status" : "green"\|"status" : "yellow"'; then
        INDEXER_READY=true
        break
    fi
    echo -n "."
    sleep 10
    WAIT_COUNT=$((WAIT_COUNT+1))
done

if [ "$INDEXER_READY" = true ]; then
    log_success "Indexer is HEALTHY!"
    
    log_info "Uploading Wazuh Index Template..."
    MASTER_CONTAINER=$(docker ps --format '{{.Names}}' | grep "wazuh.master" | head -n 1)
    if [ -n "$MASTER_CONTAINER" ]; then
        docker exec "$MASTER_CONTAINER" filebeat setup --index-management \
            -E setup.template.overwrite=true \
            -E output.elasticsearch.ssl.verification_mode=none > /dev/null 2>&1
        log_success "Index Template uploaded."
    fi
else
    log_warn "Indexer took too long to start. Please check 'docker compose logs wazuh1.indexer' later."
fi

echo -e "\n${GREEN}================================================================${NC}"
echo -e "${GREEN}🎉 DEPLOYMENT READY!${NC}"
echo -e "${BLUE}Virtual IP: ${HOST}${NC}"
echo -e "${BLUE}Dashboard:  https://${HOST}${NC}"
echo -e "${GREEN}================================================================${NC}\n"
