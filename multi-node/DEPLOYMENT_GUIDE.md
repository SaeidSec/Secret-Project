# 📘 Deployment Guide

Complete step-by-step guide for deploying the Enterprise-Grade Wazuh SIEM infrastructure.

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Pre-Deployment Checklist](#pre-deployment-checklist)
3. [Certificate Generation](#certificate-generation)
4. [Environment Configuration](#environment-configuration)
5. [Deployment Steps](#deployment-steps)
6. [Post-Deployment Configuration](#post-deployment-configuration)
7. [Agent Enrollment](#agent-enrollment)
8. [Monitoring Setup](#monitoring-setup)
9. [Verification](#verification)

## System Requirements

### Minimum Requirements (Testing)
- **CPU**: 4 cores
- **RAM**: 8 GB
- **Disk**: 50 GB SSD
- **OS**: Ubuntu 20.04+, CentOS 8+, Debian 11+
- **Docker**: 20.10+
- **Docker Compose**: 2.0+

### Recommended Requirements (Production)
- **CPU**: 8+ cores
- **RAM**: 16 GB+
- **Disk**: 200 GB+ SSD (RAID 10 recommended)
- **OS**: Ubuntu 22.04 LTS
- **Network**: 1 Gbps
- **Backup**: Automated daily backups

### Port Requirements

| Port | Service | Protocol | Purpose |
|------|---------|----------|---------|
| 443 | Wazuh Dashboard | HTTPS | Web UI access |
| 1514 | Wazuh Manager | TCP | Agent communication |
| 1515 | Wazuh Manager | TCP | Agent enrollment |
| 55000 | Wazuh API | HTTPS | API access |
| 9200 | Wazuh Indexer | HTTPS | OpenSearch API |
| 9000 | Graylog Web | HTTP | Web UI / API |
| 12201 | Graylog GELF | UDP/TCP | Log Ingestion |
| 3000 | Grafana | HTTP | Dashboards |
| 8080 | Zabbix Web | HTTP | Monitoring UI |
| 10051 | Zabbix Server | TCP | Agent communication |
| 2222 | Beelzebub Honeypot | TCP | SSH Decoy |
| 2223 | Cowrie Honeypot | TCP | SSH/Telnet Decoy |
| 8000 | Beelzebub Honeypot | TCP | HTTP Decoy |

## Pre-Deployment Checklist

### 1. Install Docker and Docker Compose

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker --version
docker-compose --version
```

### 2. Configure System Resources

```bash
# Increase vm.max_map_count for OpenSearch
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf

# Increase file descriptors
echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf
```

### 3. Configure Firewall

```bash
# UFW (Ubuntu/Debian)
sudo ufw allow 443/tcp
sudo ufw allow 1514/tcp
sudo ufw allow 1515/tcp
sudo ufw allow 55000/tcp
sudo ufw allow 3000/tcp
sudo ufw allow 8080/tcp
sudo ufw enable
```

## Certificate Generation

### Option 1: Self-Signed Certificates (Recommended for Testing)

```bash
cd multi-node
docker compose -f generate-indexer-certs.yml run --rm generator

# Verify certificates
ls -la config/wazuh_indexer_ssl_certs/
```

### Option 2: Your Own Certificates

See [CERTIFICATE_GENERATION.md](CERTIFICATE_GENERATION.md) for detailed instructions.

## Deployment Steps

### 1. Clone Repository

```bash
git clone https://github.com/SaeidSec/Docker-base-Enterprise-Grade-Wazuh-SIEM-Advanced-Load-Balancing-and-High-Availability-Architecture.git
cd Docker-base-Enterprise-Grade-Wazuh-SIEM-Advanced-Load-Balancing-and-High-Availability-Architecture/multi-node
```

### 3. Bootstrap and Generate Certificates

To ensure all folders and certificates are prepared correctly, run the bootstrap script:

```bash
cd multi-node
bash bootstrap.sh
```

### 4. Start the Stack

```bash
docker compose up -d
docker compose logs -f
```

### 4. Verify Deployment

```bash
# Check services
docker compose ps

# Check indexer cluster
curl -k -u admin:SecretPassword https://localhost:9200/_cluster/health?pretty
```

## Access Web Interfaces

| Service | URL | Credentials |
|---------|-----|-------------|
| Wazuh Dashboard | https://localhost:443 | admin / SecretPassword |
| Graylog Web | http://localhost:9000 | admin / admin |
| Zabbix Web | http://localhost:8080 | Admin / zabbix |
| Grafana | http://localhost:3000 | admin / admin |
| Beelzebub SSH | ssh localhost -p 2222 | root / (any password) |
| Cowrie SSH | ssh localhost -p 2223 | root / (any password) |

## Agent Enrollment

### Linux Agent

```bash
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list
apt-get update && apt-get install wazuh-agent

# Configure to use Virtual IP
sed -i 's/<address>.*<\/address>/<address>172.25.0.222<\/address>/' /var/ossec/etc/ossec.conf

systemctl enable wazuh-agent
systemctl start wazuh-agent
```

## Troubleshooting

### Services Not Starting

```bash
docker compose logs <service_name>
docker compose restart <service_name>
```

### Indexer Cluster Issues

```bash
curl -k -u admin:SecretPassword https://localhost:9200/_cat/nodes?v
docker restart wazuh1.indexer wazuh2.indexer wazuh3.indexer
```

---

**Deployment complete! 🎉**
