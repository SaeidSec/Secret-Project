#!/bin/bash

# Enterprise-Grade Wazuh SIEM - GitHub Publication Script
# This script prepares and publishes your enhanced Wazuh deployment to GitHub

set -e  # Exit on error

echo "🚀 Enterprise-Grade Wazuh SIEM - GitHub Publication Script"
echo "=========================================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if running from correct directory
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}Error: Please run this script from the multi-node directory${NC}"
    exit 1
fi

cd ..

echo -e "${YELLOW}Step 1: Checking repository ownership...${NC}"
if [ ! -w ".git/config" ]; then
    echo -e "${RED}Error: No write permission to .git directory${NC}"
    echo "Please run: sudo chown -R $USER:$USER /home/bear/wazuh-docker"
    exit 1
fi
echo -e "${GREEN}✓ Repository ownership OK${NC}"
echo ""

echo -e "${YELLOW}Step 2: Updating .gitignore for security...${NC}"
cat >> .gitignore << 'EOF'

# SSL Certificates (sensitive - never commit!)
multi-node/config/wazuh_indexer_ssl_certs/*.pem
multi-node/config/wazuh_indexer_ssl_certs/*.key

# Environment files with secrets
.env
multi-node/.env

# Logs
*.log
logs.txt

# Backup files
*.bak
*.backup

# Docker volumes data
**/data/
EOF
echo -e "${GREEN}✓ .gitignore updated${NC}"
echo ""

echo -e "${YELLOW}Step 3: Updating Git remote...${NC}"
git remote remove origin 2>/dev/null || true
git remote add origin https://github.com/SaeidSec/Docker-base-Enterprise-Grade-Wazuh-SIEM-Advanced-Load-Balancing-and-High-Availability-Architecture.git
echo -e "${GREEN}✓ Remote updated${NC}"
git remote -v
echo ""

echo -e "${YELLOW}Step 4: Staging all changes...${NC}"

# Add documentation
git add multi-node/README.md
git add multi-node/DEPLOYMENT_GUIDE.md
git add multi-node/CERTIFICATE_GENERATION.md
git add multi-node/CONTRIBUTING.md
git add multi-node/ARCHITECTURE_DIAGRAMS.md
git add multi-node/ZABBIX_GRAFANA_README.md
git add multi-node/.env.example

# Add configuration files
git add multi-node/config/nginx/
git add multi-node/config/keepalived/
git add multi-node/config/zabbix/
git add multi-node/config/grafana/
git add multi-node/config/velociraptor/ 2>/dev/null || true

# Add modified files
git add multi-node/docker-compose.yml
git add multi-node/config/wazuh_dashboard/wazuh.yml 2>/dev/null || true

# Add .gitignore
git add .gitignore

echo -e "${GREEN}✓ Files staged${NC}"
echo ""

echo -e "${YELLOW}Step 5: Showing what will be committed...${NC}"
git status
echo ""

echo -e "${YELLOW}Step 6: Creating commit...${NC}"
git commit -m "feat: Add enterprise-grade HA, monitoring, and threat intelligence

Major enhancements to official Wazuh Docker deployment:

High Availability:
- Dual Nginx load balancers with automatic failover
- Keepalived VRRP with Virtual IP (172.25.0.222)
- Redundant architecture for zero-downtime operations

Monitoring Stack:
- Zabbix Server with PostgreSQL backend
- Zabbix Web UI for infrastructure monitoring
- 10 Zabbix Agents monitoring all Wazuh components
- Grafana with pre-configured dashboards
- Integration with Wazuh OpenSearch for security events

Threat Intelligence & DFIR:
- MISP threat intelligence platform integration
- Velociraptor digital forensics and incident response

Documentation:
- Comprehensive deployment guide
- Certificate generation instructions
- Architecture diagrams with Mermaid
- Monitoring setup guide
- Contributing guidelines

Configuration:
- Production-ready SSL/TLS setup
- Multi-node Wazuh cluster (Master + Worker)
- 3-node Wazuh Indexer cluster
- Environment variable templates

This deployment is production-ready and suitable for enterprise SOC environments.

Tested with:
- Docker 20.10+
- Docker Compose 2.0+
- Wazuh 4.14.1
- Ubuntu 22.04 LTS"

echo -e "${GREEN}✓ Commit created${NC}"
echo ""

echo -e "${YELLOW}Step 7: Creating main branch...${NC}"
git checkout -b main 2>/dev/null || git checkout main
echo -e "${GREEN}✓ On main branch${NC}"
echo ""

echo -e "${YELLOW}Step 8: Ready to push to GitHub!${NC}"
echo ""
echo "Review the changes above. If everything looks good, run:"
echo ""
echo -e "${GREEN}git push -u origin main${NC}"
echo ""
echo "If the repository is empty or you need to force push:"
echo -e "${YELLOW}git push -u origin main --force${NC}"
echo ""
echo "🎉 Publication script complete!"
echo ""
echo "Next steps:"
echo "1. Push to GitHub with the command above"
echo "2. Configure repository settings (description, topics)"
echo "3. Create release v1.0.0"
echo "4. Share with the community!"
