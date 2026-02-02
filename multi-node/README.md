# 🛡️ Enterprise-Grade Wazuh SIEM - Multi-Node Deployment

> **Production-ready Wazuh SIEM with High Availability, Load Balancing, and Enterprise Monitoring**

## 🌟 Features

- ✅ **High Availability** - Dual Nginx load balancers with Keepalived VRRP failover
- ✅ **Multi-Node Cluster** - Wazuh Master/Worker + 3-node indexer cluster  
- ✅ **Comprehensive Monitoring** - Zabbix agents on all components + Grafana dashboards
- ✅ **Active Defense** - Beelzebub AI Honeypot & Cowrie (SSH/Telnet)
- ✅ **One-Click Deploy** - Universal `bootstrap.sh` handles all system tuning and SSL setup.

## 🚀 Quick Step Deployment

To deploy this project perfectly on any fresh device:

1. **Clone the Project**:
   ```bash
   git clone https://github.com/SaeidSec/Secret-Project.git
   cd Secret-Project/multi-node
   ```

2. **Run The Fixer/Bootstrap**:
   ```bash
   sudo bash bootstrap.sh
   ```

**The script handles all complexity:**
- ✅ Sets `vm.max_map_count`
- ✅ Generates Indexer SSL certificates
- ✅ Cleans directories & fixes permissions
- ✅ Uploads Wazuh Index Templates

## 📊 Access Services (Virtual IP: 172.25.0.222)

| Service | URL | Default Credentials |
|---------|-----|-------------------|
| **Wazuh Dashboard** | https://172.25.0.222 | admin / SecretPassword |
| **Graylog Web** | http://172.25.0.222:9000 | admin / admin |
| **Zabbix Web** | http://172.25.0.222:8080 | Admin / zabbix |
| **Grafana** | http://172.25.0.222:3000 | admin / admin |

## 🧪 Testing High Availability

```bash
# Run the automated failover test
sudo bash test_ha_failover.sh
```

---
**Deployment complete! Your Enterprise SIEM is now highly available. 🎉**
