import json

dest_path = "/home/bear/wazuh-docker/multi-node/config/grafana/dashboards/nginx-monitoring.json"

with open(dest_path, "r") as f:
    data = json.load(f)

# Fix instance variable query
for var in data["templating"]["list"]:
    if var["name"] == "instance":
        var["query"] = "label_values(cpu_usage_idle, instance)"
        var["definition"] = "label_values(cpu_usage_idle, instance)"

# Ensure all queries using instance=~"$instance" use correct format
content = json.dumps(data)
content = content.replace('instance=~ "$instance*"', 'instance=~"$instance"')
content = content.replace('instance=~"$instance*"', 'instance=~"$instance"')

data = json.loads(content)

with open(dest_path, "w") as f:
    json.dump(data, f, indent=2)

print("Nginx dashboard variables fixed")
