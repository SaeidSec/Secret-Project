# 🛡️ Infrastructure Robustness & Security Analysis

I have performed a deep-dive audit of your Wazuh/Monitoring infrastructure. While the system is functional and highly integrated, there are several "Production-Critical" weaknesses that could lead to crashes, data loss, or security breaches under load.

## 🔴 Critical Weaknesses Found

### 1. Resource Exhaustion Risk (High Priority)
- **Problem**: Almost NONE of your 20+ services have Docker resource limits (`cpu` or `memory`).
- **Risk**: If the Wazuh Indexer or Graylog experiences a spike in logs, they can consume **100% of the host RAM/CPU**, causing the entire system (including SSH and Docker) to freeze or crash.

### 2. "Blind" High Availability (Medium-High Priority)
- **Problem**: Keepalived is only monitoring the `eth0` interface. It does **not** check if Nginx is actually alive.
- **Risk**: If Nginx crashes on the MASTER node, the VIP stays there. Traffic will hit a "dead" load balancer, causing a complete outage even though the BACKUP node is perfectly healthy.

### 3. Hardcoded Secrets (Security Risk)
- **Problem**: Every password (Indexer, Postgres, API) is visible in plain text inside `docker-compose.yml`.
- **Risk**: Anyone with read access to the project folder can compromise the entire security database.

### 4. Nginx Performance & Reliability
- **Problem**: No DNS caching or failure-handling for upstreams.
- **Risk**: We already saw this with the "Boot Crash". If an upstream service restarts, Nginx might fail to reconnect or stay in a loop without proper `proxy_next_upstream` settings.

---

## 🚀 Recommended Hardening Plan

### Phase 1: Stability & Resource Management
| Service | Recommended Limit | Justification |
| :--- | :--- | :--- |
| **Indexer Nodes** | 2GB RAM / 1 CPU | Prevents JVM heap spikes from killing the host. |
| **Wazuh Manager** | 1GB RAM / 0.5 CPU | Protects log processing during flood events. |
| **Graylog** | 1.5GB RAM / 0.5 CPU | High Java overhead requires strict capping. |
| **LB Instances** | 256MB RAM / 0.2 CPU | Keeps the routing layer lean and always available. |

### Phase 2: Active HA Healthchecks
- Implement `track_script` in Keepalived to monitor the Nginx process.
- Logic: "If Nginx is DOWN, fail over the VIP to the BACKUP immediately."

### Phase 3: Secrets Externalization
- Move all passwords to a `.env` file.
- Implement `.gitignore` to prevent secret leaks to any version control.

### Phase 4: Nginx Hardening
- Implement `proxy_buffer` tuning for Grafana and Zabbix.
- Add `worker_rlimit_nofile` to match the Wazuh requirements.
