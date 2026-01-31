# 🎬 Project Showcase Video Script

This script is designed for a professional demonstration of your **Enterprise-Grade Wazuh SIEM** stack.

---

## Part 1: The Foundation (IDE & Docker)

| Scene | Visual Action | Audio/Caption |
| :--- | :--- | :--- |
| **1. Intro** | Start with your IDE (VS Code/Cursor) open. Show the project structure. | "Welcome to the Enterprise-Grade Wazuh SIEM showcase. Here is our advanced multi-node architecture." |
| **2. Startup** | Open the terminal in the IDE and run: <br>`docker compose up -d` | "We'll start the complete stack using Docker Compose. This launches 32 containers including HA managers, indexers, and monitoring tools." |
| **3. Health Check**| Run: `docker ps --format "table {{.Names}}\t{{.Status}}"` | "Everything is up and healthy. Our High-Availability nodes and monitors are ready." |

---

## Part 2: The Command Center (Dashboards)

*Open your browser and navigate through the following tabs:*

| Scene | URL | Key Features to Highlight |
| :--- | :--- | :--- |
| **4. Wazuh** | `https://172.25.0.222` | "The Wazuh Dashboard: Our central UI for security events, compliance, and agent management." |
| **5. Grafana** | `http://localhost:3000` | "Grafana: Visualizing real-time container metrics from Prometheus and Zabbix." |
| **6. Zabbix** | `http://localhost:8080` | "Zabbix: Detailed infrastructure monitoring for all 32 nodes in our cluster." |
| **7. Graylog** | `http://localhost:9000` | "Graylog: Enterprise-level log aggregation for non-security related telemetry." |

---

## Part 3: Active Defense (Trivy & Honeypots)

| Scene | Action | Audio/Caption |
| :--- | :--- | :--- |
| **8. Trivy Scan** | In terminal, run: <br>`echo "saeid12@" \| sudo -S docker exec multi-node-wazuh.master-1 /var/ossec/custom-script/trivy_scan.sh` | "Now, let's trigger a Trivy container vulnerability scan. It probes our running images for CVEs." |
| **9. Beelzebub** | Open a new terminal and run: <br>`ssh root@localhost -p 2222` | "Simulating an attack on our AI-powered Honeypot: Beelzebub. It decoys attackers with a realistic shell." |
| **10. Cowrie** | Open a new terminal and run: <br>`ssh root@localhost -p 2223` | "Next, we bait an attacker into Cowrie, our interaction-logging SSH honeypot." |

---

## Part 4: The Proof (Wazuh Alerts)

| Scene | Visual Action | Audio/Caption |
| :--- | :--- | :--- |
| **11. Verification** | Switch back to **Wazuh Dashboard** -> **Security Events**. | "Back in Wazuh, all our activities—the Trivy scan and the Honeypot intrusions—are captured as high-severity alerts." |
| **12. Detail** | Click on a Trivy alert (Rule 100203) or Cowrie login (Rule 120001). | "We get full visibility: CVE IDs, attacker IPs, and even the commands attempted in the honeypots." |
| **13. Conclusion** | Show the full dashboard view one last time. | "Enterprise-Grade Security, High-Availability, and AI-Driven Threat Intelligence—all in one stack. Thanks for watching." |

---
> [!TIP]
> **Pro Tip:** Use a screen recorder like OBS. Slow down your voice during terminal commands so viewers can see what you are typing!
