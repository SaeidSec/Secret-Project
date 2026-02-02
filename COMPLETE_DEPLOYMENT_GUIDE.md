# 🚀 Complete Deployment Guide: Wazuh SIEM to Another Device/Server

This guide provides comprehensive step-by-step instructions for deploying the Enterprise-Grade Wazuh SIEM infrastructure to any device or server.

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [System Requirements](#system-requirements)
3. [Network Requirements](#network-requirements)
4. [Pre-Deployment Setup](#pre-deployment-setup)
5. [Quick Deployment (Bootstrap Script)](#quick-deployment-bootstrap-script)
6. [Manual Deployment Steps](#manual-deployment-steps)
7. [Post-Deployment Configuration](#post-deployment-configuration)
8. [Agent Enrollment](#agent-enrollment)
9. [Access Credentials](#access-credentials)
10. [Troubleshooting](#troubleshooting)
11. [Maintenance & Monitoring](#maintenance--monitoring)

---

## 🔧 Prerequisites

### Required Software
- **Docker** 20.10+ 
- **Docker Compose** 2.0+
- **Git** for repository cloning
- **sudo/root access** for system configuration

### Supported Operating Systems
- Ubuntu 20.04+ (Recommended: 22.04 LTS)
- CentOS 8+ / RHEL 8+
- Debian 11+
- Amazon Linux 2+

---

## 💻 System Requirements

### Minimum Requirements (Testing/Development)
| Resource | Minimum |
|----------|---------|
| CPU | 4 cores |
| RAM | 8 GB |
| Storage | 50 GB SSD |
| Network | 100 Mbps |

### Recommended Requirements (Production)
| Resource | Recommended |
|----------|------------|
| CPU | 8+ cores |
| RAM | 16 GB+ |
| Storage | 200 GB+ SSD (RAID 10 recommended) |
| Network | 1 Gbps |
| Backup | Automated daily backups |

---

## 🌐 Network Requirements

### Port Mapping
| Port | Service | Protocol | Purpose |
|------|---------|----------|---------|
| 443 | Wazuh Dashboard | HTTPS | Web UI access |
| 1514 | Wazuh Manager | TCP | Agent communication |
| 1515 | Wazuh Manager | TCP | Agent enrollment |
| 55000 | Wazuh API | HTTPS | API access |
| 9200 | Wazuh Indexer | HTTPS | OpenSearch API |
| 9000 | Graylog Web | HTTP | Web UI / API |
| 12201 | Graylog GELF | UDP/TCP | Log ingestion |
| 3000 | Grafana | HTTP | Dashboards |
| 8080 | Zabbix Web | HTTP | Monitoring UI |
| 10051 | Zabbix Server | TCP | Agent communication |
| 2222 | Beelzebub Honeypot | TCP | SSH Decoy |
| 2223 | Cowrie Honeypot | TCP | SSH/Telnet Decoy |
| 8000 | Beelzebub Honeypot | TCP | HTTP Decoy |

### Network Architecture
- **Virtual IP**: 172.25.0.222 (Load Balancer)
- **Docker Network**: 172.25.0.0/16
- **Components**: 2 Nginx LBs, 3 Indexer nodes, Master/Worker Wazuh managers

---

## ⚙️ Pre-Deployment Setup

### 1. Install Docker and Docker Compose

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add current user to docker group
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

# Increase file descriptor limits
echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf

# Configure swap space (if needed)
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### 3. Configure Firewall

```bash
# For UFW (Ubuntu/Debian)
sudo ufw allow 443/tcp
sudo ufw allow 1514/tcp
sudo ufw allow 1515/tcp
sudo ufw allow 55000/tcp
sudo ufw allow 3000/tcp
sudo ufw allow 8080/tcp
sudo ufw allow 9000/tcp
sudo ufw allow 9200/tcp
sudo ufw allow 10051/tcp
sudo ufw allow 12201/tcp
sudo ufw allow 12201/udp
sudo ufw allow 2222/tcp
sudo ufw allow 2223/tcp
sudo ufw allow 8000/tcp
sudo ufw enable

# For firewalld (CentOS/RHEL)
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --permanent --add-port=1514/tcp
sudo firewall-cmd --permanent --add-port=1515/tcp
sudo firewall-cmd --permanent --add-port=55000/tcp
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --permanent --add-port=9000/tcp
sudo firewall-cmd --permanent --add-port=9200/tcp
sudo firewall-cmd --permanent --add-port=10051/tcp
sudo firewall-cmd --permanent --add-port=12201/tcp
sudo firewall-cmd --permanent --add-port=12201/udp
sudo firewall-cmd --permanent --add-port=2222/tcp
sudo firewall-cmd --permanent --add-port=2223/tcp
sudo firewall-cmd --permanent --add-port=8000/tcp
sudo firewall-cmd --reload
```

---

## 🚀 Quick Deployment (Bootstrap Script)

The bootstrap script automates the entire deployment process including SSL certificate generation and common issue fixes.

### One-Command Installation

```bash
# Clone the repository
git clone https://github.com/SaeidSec/Docker-base-Enterprise-Grade-Wazuh-SIEM-Advanced-Load-Balancing-and-High-Availability-Architecture.git
cd Docker-base-Enterprise-Grade-Wazuh-SIEM-Advanced-Load-Balancing-and-High-Availability-Architecture/multi-node

# Run the bootstrap script (requires sudo)
sudo bash bootstrap.sh
```

### What the Bootstrap Script Does:
1. ✅ Checks and fixes system settings (vm.max_map_count)
2. ✅ Creates environment configuration from template
3. ✅ Stops and cleans up existing services
4. ✅ Fixes certificate permissions and mount issues
5. ✅ Generates SSL certificates for all components
6. ✅ Starts the entire Wazuh stack
7. ✅ Waits for services to be healthy
8. ✅ Uploads Wazuh index templates
9. ✅ Verifies Graylog connectivity

---

## 🔧 Manual Deployment Steps

If you prefer manual deployment or need more control over the process:

### 1. Clone Repository and Navigate

```bash
git clone https://github.com/SaeidSec/Docker-base-Enterprise-Grade-Wazuh-SIEM-Advanced-Load-Balancing-and-High-Availability-Architecture.git
cd Docker-base-Enterprise-Grade-Wazuh-SIEM-Advanced-Load-Balancing-and-High-Availability-Architecture/multi-node
```

### 2. Configure Environment

```bash
# Create .env file from template
cp .env.example .env

# Edit the file to customize passwords and settings
nano .env
```

### 3. Generate SSL Certificates

```bash
# Generate certificates for Wazuh Indexer
docker compose -f generate-indexer-certs.yml run --rm generator

# Verify certificates are generated
ls -la config/wazuh_indexer_ssl_certs/
```

### 4. Deploy the Stack

```bash
# Start all services
docker compose up -d

# Monitor startup logs
docker compose logs -f
```

### 5. Verify Deployment

```bash
# Check all services are running
docker compose ps

# Check Wazuh Indexer cluster health
curl -k -u admin:SecretPassword https://localhost:9200/_cluster/health?pretty

# Check Wazuh Indexer nodes
curl -k -u admin:SecretPassword https://localhost:9200/_cat/nodes?v
```

---

## 📝 Post-Deployment Configuration

### 1. Access Web Interfaces

| Service | URL | Default Credentials |
|---------|-----|---------------------|
| Wazuh Dashboard | https://YOUR_SERVER_IP:443 | admin / SecretPassword |
| Graylog Web | http://YOUR_SERVER_IP:9000 | admin / admin |
| Zabbix Web | http://YOUR_SERVER_IP:8080 | Admin / zabbix |
| Grafana | http://YOUR_SERVER_IP:3000 | admin / admin |

### 2. Configure Wazuh Dashboard

1. Open Wazuh Dashboard in browser
2. Login with admin credentials
3. Navigate to **Administration → API Configuration**
4. Verify API endpoint: `https://YOUR_SERVER_IP`
5. Test connection to ensure API is working

### 3. Configure Graylog

1. Access Graylog web interface
2. Create input for log ingestion:
   - **Input Type**: Syslog TCP/UDP
   - **Port**: 1514 (if not used by Wazuh)
   - **Bind Address**: 0.0.0.0
3. Configure extractors for different log formats

---

## 🤖 Agent Enrollment

### Linux Agent Installation

```bash
# Add Wazuh repository
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list

# Install Wazuh agent
apt-get update && apt-get install wazuh-agent

# Configure agent to point to your server
sed -i 's/<address>.*<\/address>/<address>YOUR_SERVER_IP<\/address>/' /var/ossec/etc/ossec.conf

# Enable and start agent
systemctl enable wazuh-agent
systemctl start wazuh-agent
```

### Windows Agent Installation

```powershell
# Download Wazuh agent
Invoke-WebRequest -Uri "https://packages.wazuh.com/4.x/windows/wazuh-agent-4.14.1-1.msi" -OutFile "wazuh-agent.msi"

# Install with server configuration
msiexec.exe /i wazuh-agent.msi /q WAZUH_MANAGER="YOUR_SERVER_IP" WAZUH_REGISTRATION_SERVER="YOUR_SERVER_IP"

# Start the service
net start WazuhSvc
```

### Verify Agent Enrollment

1. Log into Wazuh Dashboard
2. Navigate to **Agents Management**
3. Verify your agent appears in the list
4. Check agent status is "Active"

---

## 🔐 Access Credentials

### Default Credentials (Change in Production)

| Service | Username | Password | Where to Change |
|---------|----------|----------|-----------------|
| Wazuh Dashboard | admin | SecretPassword | `.env` file |
| Wazuh API | wazuh-wui | MyS3cr37P450r.*- | `.env` file |
| Grafana | admin | admin | `.env` file |
| Zabbix | Admin | zabbix | `.env` file |
| Graylog | admin | admin | Graylog Web UI |

### Security Recommendations

1. **Change all default passwords** before production deployment
2. **Use strong, unique passwords** for each service
3. **Enable SSL/TLS** for all web interfaces
4. **Configure firewall** to restrict access to management interfaces
5. **Regularly update** components and security patches

---

## 🔧 Troubleshooting

### Common Issues and Solutions

#### Services Not Starting

```bash
# Check service logs
docker compose logs <service_name>

# Restart specific service
docker compose restart <service_name>

# Check system resources
docker stats
df -h
free -h
```

#### SSL Certificate Issues

```bash
# Regenerate certificates
docker compose -f generate-indexer-certs.yml run --rm generator

# Fix permissions
sudo find ./config/wazuh_indexer_ssl_certs -type f -name "*.pem" -exec chmod 644 {} +
sudo find ./config/wazuh_indexer_ssl_certs -type f -name "*-key.pem" -exec chmod 644 {} +
```

#### Wazuh Indexer Cluster Issues

```bash
# Check cluster health
curl -k -u admin:SecretPassword https://localhost:9200/_cluster/health?pretty

# Check individual nodes
curl -k -u admin:SecretPassword https://localhost:9200/_cat/nodes?v

# Restart indexer nodes
docker restart wazuh1.indexer wazuh2.indexer wazuh3.indexer
```

#### Agent Connection Issues

```bash
# Check agent status
/var/ossec/bin/agent-control -l

# Test connectivity from agent
curl -k https://YOUR_SERVER_IP:55000

# Check manager logs
docker compose logs wazuh.master
docker compose logs wazuh.worker
```

#### Memory Issues

```bash
# Check system memory
free -h
docker stats

# Increase swap if needed
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

#### Disk Space Issues

```bash
# Check disk usage
df -h
docker system df

# Clean up unused Docker resources
docker system prune -a
```

---

## 📊 Maintenance & Monitoring

### Regular Maintenance Tasks

#### 1. Backup Configuration

```bash
# Create backup script
cat > backup_wazuh.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/backup/wazuh-$(date +%Y%m%d)"
mkdir -p $BACKUP_DIR

# Backup volumes
docker run --rm -v wazuh-indexer-data-1:/data -v $BACKUP_DIR:/backup ubuntu tar czf /backup/indexer-data-1.tar.gz -C /data .
docker run --rm -v wazuh-indexer-data-2:/data -v $BACKUP_DIR:/backup ubuntu tar czf /backup/indexer-data-2.tar.gz -C /data .
docker run --rm -v wazuh-indexer-data-3:/data -v $BACKUP_DIR:/backup ubuntu tar czf /backup/indexer-data-3.tar.gz -C /data .

# Backup configurations
cp -r config/ $BACKUP_DIR/

echo "Backup completed: $BACKUP_DIR"
EOF

chmod +x backup_wazuh.sh
```

#### 2. Log Rotation

```bash
# Configure log rotation for Docker containers
cat > /etc/logrotate.d/wazuh-docker << 'EOF'
/var/lib/docker/containers/*/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0644 root root
}
EOF
```

#### 3. Health Monitoring

```bash
# Create health check script
cat > health_check.sh << 'EOF'
#!/bin/bash

# Check Wazuh Indexer
if curl -k -s -u admin:SecretPassword https://localhost:9200/_cluster/health | grep -q '"status":"green\|yellow"'; then
    echo "✅ Wazuh Indexer: Healthy"
else
    echo "❌ Wazuh Indexer: Unhealthy"
fi

# Check Wazuh Dashboard
if curl -k -s https://localhost:443 > /dev/null; then
    echo "✅ Wazuh Dashboard: Healthy"
else
    echo "❌ Wazuh Dashboard: Unhealthy"
fi

# Check running containers
echo "📊 Docker Containers Status:"
docker compose ps
EOF

chmod +x health_check.sh
```

### Monitoring Integration

#### Zabbix Monitoring
- Pre-configured Zabbix agents monitor all components
- Access Zabbix Web: http://YOUR_SERVER_IP:8080
- Default dashboards available for system metrics

#### Grafana Dashboards
- Pre-built dashboards for Wazuh and system metrics
- Access Grafana: http://YOUR_SERVER_IP:3000
- OpenSearch and Prometheus data sources configured

### Scaling Considerations

#### Horizontal Scaling
- Add more indexer nodes by updating docker-compose.yml
- Configure load balancer for additional Wazuh managers
- Consider separate servers for different roles in large deployments

#### Performance Tuning
- Adjust JVM heap size for indexer nodes
- Optimize file descriptor limits
- Configure appropriate retention periods for logs

---

## 🎉 Deployment Complete!

Your Enterprise-Grade Wazuh SIEM is now deployed and ready for use!

### Next Steps:
1. **Change default passwords** for all services
2. **Configure agents** on your endpoints
3. **Set up monitoring alerts** in Zabbix
4. **Create backup schedules** for your data
5. **Document your specific configuration** changes

### Support:
- **GitHub Repository**: [SaeidSec/Wazuh-Docker](https://github.com/SaeidSec/Docker-base-Enterprise-Grade-Wazuh-SIEM-Advanced-Load-Balancing-and-High-Availability-Architecture)
- **Wazuh Documentation**: [https://documentation.wazuh.com](https://documentation.wazuh.com)
- **Community Support**: [Wazuh Community Slack](https://wazuh.com/community/)

---

**🛡️ Your SIEM infrastructure is now operational with high availability, advanced monitoring, and active defense capabilities!**