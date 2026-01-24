import json
import re

dashboard_path = '/home/bear/wazuh-docker/multi-node/config/grafana/dashboards/advanced-docker.json'

with open(dashboard_path, 'r') as f:
    data = json.load(f)

# 1. Fix "Containers" Singlestat Panel
# Old: count(rate(container_last_seen{name=~".+"}[$interval]))
# New: count(container_start_time_seconds{name=~".+"})
# We traverse rows -> panels
for row in data.get('rows', []):
    for panel in row.get('panels', []):
        if panel.get('title') == 'Containers':
            print("Found 'Containers' panel. Patching targets...")
            for target in panel.get('targets', []):
                if 'container_last_seen' in target.get('expr', ''):
                    target['expr'] = 'count(container_start_time_seconds{name=~".+"})'
                    print("  -> Replaced container_last_seen query")

# 2. Fix Variables
# Check templating list
if 'templating' in data and 'list' in data['templating']:
    for var in data['templating']['list']:
        if var.get('name') == 'containergroup':
            # container_group label often missing in modern cAdvisor setups or named differently
            # changing to just a dummy valid query or name
             if 'label_values(container_group)' in var.get('query', ''):
                 # Fallback to names if group missing, or just keep it but set includeAll
                 print("Found 'containergroup' variable. Patching query...")
                 var['query'] = 'label_values(name)' 
                 
# 3. Save with indentation for readability
with open(dashboard_path, 'w') as f:
    json.dump(data, f, indent=2)

print("Dashboard patched and saved successfully.")
