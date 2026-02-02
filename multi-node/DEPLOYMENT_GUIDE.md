# 📘 Enterprise-Grade Wazuh SIEM Deployment Guide

Complete step-by-step guide for deploying the Enterprise-Grade Wazuh SIEM infrastructure with High Availability (HA) and Advanced Load Balancing.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [System Requirements](#system-requirements)
3. [Pre-Deployment Checklist](#pre-deployment-checklist)
4. [Deployment Steps (The Standard Way)](#deployment-steps-the-standard-way)
5. [Infrastructure Access (VIP Based)](#infrastructure-access-vip-based)
6. [HA Failover Testing](#ha-failover-testing)
7. [Agent Enrollment](#agent-enrollment)
8. [Monitoring & Security Stack](#monitoring--security-stack)
9. [Troubleshooting](#troubleshooting)

## Architecture Overview

This deployment uses a **Multi-Node High Availability** architecture:
- **Load Balancing**: Dual Nginx nodes with Keepalived for Virtual IP (VIP) management.
- **Wazuh Cluster**: 1 Master node and 2 Worker nodes.
- **Indexer Cluster**: 3-node OpenSearch/Wazuh Indexer cluster for data redundancy.
- **Security Stack**: Integrated Graylog for log management, Zabbix for monitoring, and Grafana for visualization.
- **Honeypots**: Integrated Beelzebub and Cowrie honeypots for proactive threat detection.

**Virtual IP (VIP):** `172.25.0.222`

## System Requirements

### Recommended Requirements (Production)
- **CPU**: 8+ cores
- **RAM**: 16 GB+
- **Disk**: 200 GB+ SSD
- **OS**: Ubuntu 22.04 LTS (Recommended)
- **Docker**: 20.10+
- **Docker Compose**: 2.0+

### Port Requirements

| Port | Service | Protocol | Purpose |
|------|---------|----------|---------|
| 443 | Wazuh Dashboard | HTTPS | Web UI access (via VIP) |
| 1514 | Wazuh Manager | TCP | Agent communication |
| 1515 | Wazuh Manager | TCP | Agent enrollment |
| 55000 | Wazuh API | HTTPS | API access |
| 9000 | Graylog Web | HTTP | Web UI / API |
| 3000 | Grafana | HTTP | Dashboards |
| 8080 | Zabbix Web | HTTP | Monitoring UI |
| 2222 | Beelzebub Honeypot | TCP | SSH Decoy |
| 2223 | Cowrie Honeypot | TCP | SSH/Telnet Decoy |

## Pre-Deployment Checklist

### 1. Configure System Resources

```bash
# Increase vm.max_map_count for OpenSearch (Mandatory)
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf

# Increase file descriptors
echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf
```

## Deployment Steps (The Standard Way)

We use a universal `bootstrap.sh` script to handle environment preparation, certificate generation, and permission fixes automatically.

### 1. Clone & Prepare

```bash
git clone https://github.com/SaeidSec/Secret-Project.git
cd Secret-Project/multi-node
```

### 2. Run Bootstrap Script

This is the recommended way to start the stack. It fixes common mount issues and generates all necessary SSL certificates.

```bash
sudo bash bootstrap.sh
```

> [!IMPORTANT]
> The bootstrap script will:
> 1. Set `vm.max_map_count`.
> 2. Generate Indexer SSL certificates.
> 3. Fix directory permissions for Graylog and Wazuh.
> 4. Start all containers in the correct order.
> 5. Upload the Wazuh Index Template automatically.

## Infrastructure Access (VIP Based)

All services are exposed via the **Virtual IP: 172.25.0.222**.

| Service | URL | Default Credentials |
|---------|-----|---------------------|
| **Wazuh Dashboard** | https://172.25.0.222 | admin / SecretPassword |
| **Graylog Web** | http://172.25.0.222:9000 | admin / admin |
| **Zabbix Monitoring** | http://172.25.0.222:8080 | Admin / zabbix |
| **Grafana Dashboards** | http://172.25.0.222:3000 | admin / admin |

## HA Failover Testing

To verify that the Load Balancer is working correctly and the VIP is highly available:

```bash
sudo bash test_ha_failover.sh
```
This script will:
1. Ping the VIP.
2. Stop the primary Load Balancer.
3. Verify connectivity remains via the secondary node.
4. Restart the primary node and verify failback.

## Agent Enrollment

### Linux Agent Configuration

When installing agents, ensure they point to the **Virtual IP** for high availability.

```bash
# Install agent (Debian/Ubuntu example)
wget https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.7.2-1_amd64.deb
sudo WAZUH_MANAGER='172.25.0.222' dpkg -i wazuh-agent_4.7.2-1_amd64.deb

# Or update existing config
sudo sed -i 's/<address>.*<\/address>/<address>172.25.0.222<\/address>/' /var/ossec/etc/ossec.conf
sudo systemctl restart wazuh-agent
```

## Monitoring & Security Stack

### Honeypot Interaction
- **Beelzebub SSH**: `ssh 172.25.0.222 -p 2222`
- **Cowrie SSH**: `ssh 172.25.0.222 -p 2223`
- Logs are automatically forwarded to Graylog and Wazuh.

### Vulnerability Scanning
Trivy is integrated into the Wazuh Manager. Scans can be triggered via the Wazuh API or scheduled in the manager configuration.

## Troubleshooting

### Check Service Health
```bash
docker compose ps
docker compose logs -f <service_name>
```

### Common Fixes
If you see "Not a directory" errors or SSL issues, re-run the bootstrap script:
```bash
sudo bash bootstrap.sh
```

---

**Deployment complete! Your Enterprise SIEM is now highly available. 🎉**
