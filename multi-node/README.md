# 🛡️ Enterprise-Grade Wazuh SIEM - Multi-Node Deployment

[![License: GPL v2](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker)](https://www.docker.com/)
[![Wazuh](https://img.shields.io/badge/Wazuh-4.14.1-00A4EF)](https://wazuh.com/)

> **Production-ready Wazuh SIEM with High Availability, Load Balancing, and Enterprise Monitoring**

## 🌟 Features

- ✅ **High Availability** - Dual Nginx load balancers with Keepalived VRRP failover
- ✅ **Multi-Node Cluster** - Wazuh Master/Worker + 3-node indexer cluster  
- ✅ **Comprehensive Monitoring** - Zabbix agents on all components + Grafana dashboards
- ✅ **Active Defense** - Beelzebub AI Honeypot (SSH & HTTP decoys) & Cowrie (SSH/Telnet)
- ✅ **Advanced Log Management** - Graylog 7.0.3 for non-security and multi-source log analysis
- ✅ **Production-Ready** - SSL/TLS encryption with automated certificate generation

## 📊 Architecture

This deployment includes:

**Wazuh Core:**
- 1x Wazuh Master Manager (API, enrollment, cluster coordination)
- 1x Wazuh Worker Manager (event processing)
- 3x Wazuh Indexers (OpenSearch cluster)
- 1x Wazuh Dashboard (Web UI)

**High Availability:**
- 2x Nginx Load Balancers (redundant reverse proxies)
- 2x Keepalived instances (VRRP with Virtual IP 172.25.0.222)

**Monitoring Stack:**
- Zabbix Server + PostgreSQL database
- Zabbix Web UI (Port 8080)
- 10x Zabbix Agents (monitoring all components)
- Grafana (Port 3000) with pre-configured dashboards


**Network Sensors & Log Management:**
- Graylog 7.0.3 (Enterprise Log Management)
- Beelzebub Honeypot (Active Decoy Layer)
- Cowrie Honeypot (SSH/Telnet Interaction)
- Integrated Zabbix Agents (Health & Traffic Monitoring)

## 🚀 Quick Start

### 1. Generate Certificates

```bash
docker compose -f generate-indexer-certs.yml run --rm generator
```

### 2. Deploy the Stack

```bash
docker compose up -d
```

### 3. Access Services

| Service | URL | Credentials |
|---------|-----|-------------|
| Wazuh Dashboard | https://localhost:443 | admin / SecretPassword |
| Graylog Web | http://localhost:9000 | admin / admin |
| Zabbix Web | http://localhost:8080 | Admin / zabbix |
| Grafana | http://localhost:3000 | admin / admin |
| Beelzebub SSH | ssh localhost -p 2222 | root / (any password) |
| Cowrie SSH | ssh localhost -p 2223 | root / (any password) |
| Beelzebub HTTP | http://localhost:8000 | (Decoy WordPress) |

## 📖 Documentation

- [📘 Deployment Guide](DEPLOYMENT_GUIDE.md) - Complete deployment instructions
- [🔐 Certificate Generation](CERTIFICATE_GENERATION.md) - SSL/TLS setup guide
- [🏗️ Architecture Diagrams](ARCHITECTURE_DIAGRAMS.md) - System architecture
- [🧠 Technical Analysis](TECHNICAL_ANALYSIS.md) - Deep dive into design & roadmap
- [📊 Monitoring Setup](ZABBIX_GRAFANA_README.md) - Zabbix & Grafana configuration
- [🤝 Contributing](CONTRIBUTING.md) - Contribution guidelines

## 🔧 Configuration Files

```
config/
├── nginx/              # Load balancer configuration
│   └── nginx_ha.conf
├── keepalived/         # High availability configuration
│   ├── master.conf
│   └── backup.conf
├── zabbix/             # Monitoring configuration
│   └── zabbix_server.conf
├── grafana/            # Dashboards and datasources
│   ├── provisioning/
│   └── dashboards/
├── wazuh_cluster/      # Wazuh manager configurations
├── wazuh_indexer/      # Indexer configurations
├── wazuh_dashboard/    # Dashboard configuration
└── wazuh_indexer_ssl_certs/  # SSL certificates
```

## 🧪 Testing High Availability

```bash
# Stop primary load balancer
docker stop nginx-lb-1 keepalived-1

# Verify VIP fails over to backup
docker exec nginx-lb-2 ip addr show | grep 172.25.0.222

# Test dashboard access (should still work)
curl -k https://172.25.0.222:443

# Restart primary
docker start nginx-lb-1 keepalived-1
```

## 📈 Monitoring

### Zabbix Metrics
- CPU, Memory, Disk I/O for all components
- Network traffic and errors
- Service availability
- Custom triggers and alerts

### Grafana Dashboards
- Wazuh Infrastructure Overview
- Security Events Timeline
- Agent Connectivity Status
- Cluster Health Monitoring

## 🔒 Security

**Change default passwords:**
```bash
# Update in docker-compose.yml:
- INDEXER_PASSWORD=<strong_password>
- WAZUH_API_PASSWORD=<strong_password>
- POSTGRES_PASSWORD=<strong_password>
- GF_SECURITY_ADMIN_PASSWORD=<strong_password>
```

**Use valid SSL certificates** for production (see CERTIFICATE_GENERATION.md)

## 📂 Project Structure

- `build-docker-images/`: Scripts to build custom Wazuh images.
- `docs/`: Internal project documentation source.
- `indexer-certs-creator/`: Application to generate SSL/TLS certificates.
- `wazuh-agent/`: Standalone Wazuh agent for connectivity testing.
- `tools/`: Maintenance and utility scripts.
- `config/`: Configuration files for all components.
- `docker-compose.yml`: Main deployment orchestration file.

## 🛠️ Testing with Standalone Agent

To test the cluster connectivity, you can deploy a standalone agent container:

```bash
cd wazuh-agent
docker compose up -d
```

This agent is pre-configured to connect to the HA Virtual IP (`172.25.0.222`) and join the `wazuh-net` network.

## 🐛 Troubleshooting

### Check Service Status
```bash
docker compose ps
docker compose logs <service_name>
```

### Verify Indexer Cluster
```bash
curl -k -u admin:SecretPassword https://localhost:9200/_cluster/health?pretty
```

### Test Agent Connectivity
```bash
telnet 172.25.0.222 1514
```

## 🤝 Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md)

## 📝 License

GNU General Public License v2.0 - see [LICENSE](LICENSE)

## 🙏 Acknowledgments

Based on [wazuh/wazuh-docker](https://github.com/wazuh/wazuh-docker) with enterprise enhancements.

---

**Made with ❤️ for the Security Community**

For detailed deployment instructions, see [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
