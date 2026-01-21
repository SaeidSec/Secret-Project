import json

source_path = "/home/bear/wazuh-docker/multi-node/14900_rev2.json"
dest_path = "/home/bear/wazuh-docker/multi-node/config/grafana/dashboards/nginx-monitoring.json"

with open(source_path, "r") as f:
    data = json.load(f)

# Fix title
data["title"] = "Nginx Multi-Instance Monitoring"
data["uid"] = "nginx-monitoring"

# The dashboard has a global datasource variable or uses __inputs
# Let's replace all occurrences of the datasource placeholder
content = json.dumps(data)
# Based on the file content seen earlier: DS_PROMETHEUS.INTERNAL-ODMONT.COM
content = content.replace("${DS_PROMETHEUS.INTERNAL-ODMONT.COM}", "Prometheus")

# Also replace any other possible datasource vars if they exist
# Looking at the file, it uses $datasource in many places
data = json.loads(content)

# Fix templating for datasource if it exists
if "templating" in data:
    for var in data["templating"]["list"]:
        if var["type"] == "datasource":
             var["query"] = "prometheus"
             var["current"] = {"text": "Prometheus", "value": "Prometheus"}

with open(dest_path, "w") as f:
    json.dump(data, f, indent=2)

print("Nginx dashboard fixed and saved")
