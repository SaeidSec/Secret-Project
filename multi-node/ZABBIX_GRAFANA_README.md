# Monitoring Stack Integration for Wazuh Docker

This integration adds enterprise-grade monitoring and visualization to your Wazuh HA environment using Zabbix, Prometheus, and Grafana.

## 🚀 What's Included

### Zabbix Monitoring Stack
- **Zabbix Server**: Core monitoring engine
- **Zabbix Web UI**: Configuration and monitoring interface (Port 8080)
- **PostgreSQL Database**: Backend storage for Zabbix
- **Zabbix Agents**: Monitoring agents for all Wazuh components:
  - Wazuh Master Manager
  - Wazuh Worker Manager
  - Wazuh Indexer 1, 2, 3
  - Wazuh Dashboard

### Prometheus Monitoring Stack
- **Prometheus Server**: Time-series metrics collection (Port 9090)
- **cAdvisor**: Docker container metrics exporter
- **Node Exporter**: Host system metrics exporter
- **Pre-configured Scraping**: Automatic metrics collection from all services

### Grafana Visualization
- **Grafana**: Advanced dashboards and visualization (Port 3000)
- **Pre-configured Data Sources**:
  - Wazuh OpenSearch (security events)
  - Zabbix (infrastructure metrics)
  - Prometheus (container and host metrics)
  - PostgreSQL (direct database access)
- **Custom Dashboards**: 
  - Wazuh Infrastructure Overview
  - Docker Containers Monitoring

## 📋 Prerequisites

- Docker and Docker Compose installed
- Existing Wazuh multi-node environment running
- Ports available: 3000 (Grafana), 8080 (Zabbix), 9090 (Prometheus), 10051 (Zabbix Server)

## 🔧 Quick Start

### 1. Start All Services

```bash
cd /home/bear/wazuh-docker/multi-node
docker-compose up -d
```

### 2. Wait for Services to Initialize

```bash
# Check service status
docker-compose ps

# Monitor Zabbix server logs
docker-compose logs -f zabbix-server

# Monitor Grafana logs
docker-compose logs -f grafana
```

### 3. Access Web Interfaces

**Zabbix Web UI**
- URL: http://172.25.0.222:8080
- Username: `Admin`
- Password: `zabbix`

**Grafana**
- URL: http://172.25.0.222:3000
- Username: `admin`
- Password: `admin` (you'll be prompted to change this)

**Prometheus**
- URL: http://172.25.0.222:9090
- No authentication required

## 🎯 Initial Configuration

### Zabbix Setup

1. **Login to Zabbix** (http://172.25.0.222:8080)

2. **Create Host Group**:
   - Go to: Configuration → Host groups
   - Click: Create host group
   - Name: `Wazuh`
   - Save

3. **Add Hosts** (auto-discovery should find them, but manual setup):
   
   For each Wazuh component, add a host:
   - Configuration → Hosts → Create host
   - Host name: `wazuh.master` (or respective hostname)
   - Groups: `Wazuh`
   - Agent interfaces: 
     - IP address: Use Docker service name (e.g., `wazuh.master`)
     - Port: `10050`
   - Templates: Add `Linux by Zabbix agent`

4. **Verify Monitoring**:
   - Monitoring → Latest data
   - Select host group: `Wazuh`
   - You should see CPU, memory, disk metrics

### Grafana Setup

1. **Login to Grafana** (http://172.25.0.222:3000)

2. **Verify Data Sources**:
   - Go to: Configuration → Data sources
   - You should see:
     - ✅ Wazuh-OpenSearch
     - ✅ Zabbix
     - ✅ Prometheus
     - ✅ Zabbix-PostgreSQL

3. **Access Pre-built Dashboards**:
   - Go to: Dashboards → Browse
   - Open: "Wazuh Infrastructure Overview"
     - CPU/Memory gauges for Wazuh components
     - Security alerts timeline
     - Service status indicators
   - Open: "Docker Containers Monitoring"
     - Container CPU, memory, and network usage
     - Real-time Docker metrics

4. **Install Additional Plugins** (if needed):
   ```bash
   docker exec -it grafana grafana-cli plugins install grafana-piechart-panel
   docker-compose restart grafana
   ```

## 📊 Available Metrics

### From Zabbix
- CPU utilization
- Memory usage
- Disk I/O
- Network traffic
- Process monitoring
- Service availability
- Custom triggers and alerts

### From Prometheus
- Docker container CPU, memory, network, and disk usage
- Host system metrics (CPU, memory, disk, network)
- Service-specific metrics (Grafana, Prometheus itself)
- Custom application metrics

### From Wazuh Indexer (OpenSearch)
- Security alerts and events
- Agent status
- Rule triggers
- Compliance data
- File integrity monitoring events

## 🔔 Setting Up Alerts

### Zabbix Alerts

1. **Configure Email Notifications**:
   - Administration → Media types
   - Configure Email settings
   - Test notification

2. **Create Triggers**:
   - Configuration → Hosts → Select host → Triggers
   - Create trigger for high CPU, memory, etc.

### Grafana Alerts

1. **Configure Notification Channels**:
   - Alerting → Notification channels
   - Add channel (Email, Slack, etc.)

2. **Add Alert Rules to Dashboards**:
   - Edit panel → Alert tab
   - Define conditions and notifications

## 🛠️ Troubleshooting

### Zabbix Server Not Starting

```bash
# Check logs
docker-compose logs zabbix-server

# Verify database connection
docker exec -it zabbix-postgres psql -U zabbix -d zabbix -c "\dt"
```

### Grafana Can't Connect to Data Sources

```bash
# Check network connectivity
docker exec -it grafana ping wazuh1.indexer
docker exec -it grafana ping zabbix-server

# Verify OpenSearch is accessible
curl -k -u admin:SecretPassword https://localhost:9200
```

### Zabbix Agents Not Reporting

```bash
# Check agent status
docker-compose logs zabbix-agent-master

# Test connectivity from Zabbix server
docker exec -it zabbix-server zabbix_get -s wazuh.master -k agent.ping
```

## 🔐 Security Recommendations

1. **Change Default Passwords**:
   ```yaml
   # In docker-compose.yml, update:
   - POSTGRES_PASSWORD=<strong_password>
   - GF_SECURITY_ADMIN_PASSWORD=<strong_password>
   ```

2. **Enable HTTPS**:
   - Configure reverse proxy (Nginx) for Grafana and Zabbix
   - Use Let's Encrypt certificates

3. **Restrict Access**:
   - Use firewall rules to limit access to ports 3000 (Grafana), 8080 (Zabbix), 9090 (Prometheus) on the VIP `172.25.0.222`
   - Implement authentication proxy

## 📈 Performance Tuning

### For Large Deployments

Edit `config/zabbix/zabbix_server.conf`:

```conf
StartPollers=10
CacheSize=64M
HistoryCacheSize=32M
TrendCacheSize=8M
```

Then restart:
```bash
docker-compose restart zabbix-server
```

## 🔄 Backup and Restore

### Backup Zabbix Database

```bash
docker exec zabbix-postgres pg_dump -U zabbix zabbix > zabbix_backup.sql
```

### Backup Grafana Dashboards

```bash
docker exec grafana grafana-cli admin export-dashboard > grafana_dashboards.json
```

## 📚 Additional Resources

- [Zabbix Documentation](https://www.zabbix.com/documentation/current/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Wazuh Documentation](https://documentation.wazuh.com/)

## 🎉 Next Steps

1. Customize dashboards for your specific needs
2. Set up alerting rules
3. Create custom Zabbix templates for Wazuh-specific metrics
4. Integrate with your incident management system
5. Schedule regular backups

---

**Need Help?** Check the logs first:
```bash
docker-compose logs -f zabbix-server grafana
```
