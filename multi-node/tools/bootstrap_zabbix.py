import requests
import json

ZABBIX_URL = "http://172.25.0.222:8080/api_jsonrpc.php"
ZABBIX_USER = "Admin"
ZABBIX_PASS = "zabbix"

def zabbix_api(method, params, auth=None):
    payload = {
        "jsonrpc": "2.0",
        "method": method,
        "params": params,
        "id": 1
    }
    if auth:
        payload["auth"] = auth
    
    response = requests.post(ZABBIX_URL, json=payload)
    return response.json()

def main():
    # Login
    login = zabbix_api("user.login", {"username": ZABBIX_USER, "password": ZABBIX_PASS})
    if "error" in login:
        print(f"Login failed: {login['error']}")
        return
    auth = login["result"]
    print("Logged in to Zabbix API")

    # Create Host Group
    group_name = "Wazuh"
    group_get = zabbix_api("hostgroup.get", {"filter": {"name": [group_name]}}, auth)
    if not group_get["result"]:
        group_create = zabbix_api("hostgroup.create", {"name": group_name}, auth)
        group_id = group_create["result"]["groupids"][0]
        print(f"Created Host Group: {group_name}")
    else:
        group_id = group_get["result"][0]["groupid"]
        print(f"Host Group {group_name} already exists")

    # Setup Hosts
    hosts = [
        {"host": "wazuh.master", "ip": "wazuh.master"},
        {"host": "wazuh.worker", "ip": "wazuh.worker"},
        {"host": "wazuh1.indexer", "ip": "wazuh1.indexer"},
        {"host": "wazuh2.indexer", "ip": "wazuh2.indexer"},
        {"host": "wazuh3.indexer", "ip": "wazuh3.indexer"},
        {"host": "wazuh.dashboard", "ip": "wazuh.dashboard"},
        {"host": "nginx-lb-1", "ip": "nginx-lb-1"},
        {"host": "nginx-lb-2", "ip": "nginx-lb-2"},
        {"host": "grafana", "ip": "grafana"},
        {"host": "zabbix-postgres", "ip": "zabbix-postgres"},
        {"host": "beelzebub", "ip": "beelzebub"},
        {"host": "cowrie", "ip": "cowrie"},
        {"host": "graylog", "ip": "graylog"}
    ]

    template_id = "10001" # Linux by Zabbix agent

    for h in hosts:
        host_get = zabbix_api("host.get", {"filter": {"host": [h["host"]]}}, auth)
        if not host_get["result"]:
            host_create = zabbix_api("host.create", {
                "host": h["host"],
                "interfaces": [{
                    "type": 1,
                    "main": 1,
                    "useip": 0,
                    "ip": "",
                    "dns": h["ip"],
                    "port": "10050"
                }],
                "groups": [{"groupid": group_id}],
                "templates": [{"templateid": template_id}]
            }, auth)
            if "error" in host_create:
                print(f"Failed to create host {h['host']}: {host_create['error']}")
            else:
                print(f"Created Host: {h['host']}")
        else:
            print(f"Host {h['host']} already exists")

if __name__ == "__main__":
    main()
