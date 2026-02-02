# 🛡️ Enterprise-Grade Wazuh SIEM - Advanced Docker Stack

> **The most stable and feature-rich Wazuh SIEM deployment with High Availability, Monitoring, and Active Defense.**

This repository provides a production-hardened, multi-node Wazuh SIEM orchestration using Docker. It goes beyond the standard Wazuh deployment by integrating enterprise monitoring, redundancy, and automated security sensors.

## 🌟 Key Capabilities

- ✅ **High Availability**: Dual Nginx Load Balancers with Keepalived VRRP failover.
- ✅ **Multi-Node Cluster**: 3-node Wazuh Indexer (OpenSearch) cluster and Master/Worker architecture.
- ✅ **Universal Bootstrap**: One script to fix common Docker mount, SSL, and Indexer errors on any device.
- ✅ **Advanced Monitoring**: Full stack monitoring with Zabbix and Grafana.
- ✅ **Active Defense**: Integrated Beelzebub (AI-powered) and Cowrie honeypots for threat intel.
- ✅ **Log Management**: Graylog 7.0 for advanced log parsing and storage.

## 🚀 One-Command Installation (Fast Install)

To install this project perfectly on any Linux device (Ubuntu/CentOS/Debian):

```bash
git clone https://github.com/SaeidSec/Secret-Project.git
cd Secret-Project/multi-node
sudo bash bootstrap.sh
```

The script will automatically handle system tuning, certificate generation, and even fix common dashboard errors.

## 📊 Quick Links

- [🏗️ Multi-Node Details](multi-node/README.md)
- [📘 Full Deployment Guide](multi-node/DEPLOYMENT_GUIDE.md)
- [🏗️ HA Resilience Report](multi-node/HA_ARCHITECTURE_RESILIENCE_REPORT.md)

---
**Maintained by**: [SaeidSec](https://github.com/SaeidSec)
**License**: GPLv2
