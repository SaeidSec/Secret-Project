import json
import re

path = "/home/bear/wazuh-docker/multi-node/config/grafana/dashboards/advanced-docker.json"
with open("/home/bear/wazuh-docker/multi-node/893_rev5.json", "r") as f:
    data = json.load(f)

# Fix Datasource
content = json.dumps(data)
content = content.replace("${DS_PROMETHEUS}", "Prometheus")

# Fix Metric Names
metrics_map = {
    "node_boot_time": "node_boot_time_seconds",
    "node_memory_MemTotal": "node_memory_MemTotal_bytes",
    "node_memory_MemAvailable": "node_memory_MemAvailable_bytes",
    "node_filesystem_size": "node_filesystem_size_bytes",
    "node_filesystem_free": "node_filesystem_free_bytes",
    "node_memory_SwapTotal": "node_memory_SwapTotal_bytes",
    "node_memory_SwapFree": "node_memory_SwapFree_bytes",
    "node_memory_Active": "node_memory_Active_bytes",
    "node_memory_MemFree": "node_memory_MemFree_bytes",
    "node_memory_Inactive": "node_memory_Inactive_bytes",
    "node_cpu": "node_cpu_seconds_total"
}
for old, new in metrics_map.items():
    content = content.replace(old, new)

# Fix Server Variable and Usage
# 1. Variable regex
content = content.replace('"/([^:]+):.*/"', '""')
# 2. Variable query (using node_load1 instead of boot time for faster refresh/reliability)
content = content.replace('label_values(node_boot_time_seconds, instance)', 'label_values(node_load1, instance)')

# 3. Usage in queries: change "$server:.*" to "$server"
content = content.replace('$server:.*', '$server')

with open(path, "w") as f:
    f.write(content)

print("Dashboard fixed successfully")
