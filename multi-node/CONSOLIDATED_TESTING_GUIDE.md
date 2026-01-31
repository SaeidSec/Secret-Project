# 🛡️ Consolidated Security Testing Guide

This guide provides step-by-step instructions to test **Trivy** (Container Vulnerability Scanner), **Beelzebub** (AI-Powered Honeypot), and **Cowrie** (SSH/Telnet Honeypot) within your Wazuh SIEM stack.

---

## 1. Trivy (Container Security)

Trivy scans your Docker images for vulnerabilities and sends the results to Wazuh.

### Steps to Test:
1. **Pull a Vulnerable Image:**
   ```bash
   echo "saeid12@" | sudo -S docker pull nginx:1.19.0
   ```
2. **Trigger a Manual Scan:**
   ```bash
   echo "saeid12@" | sudo -S docker exec multi-node-wazuh.master-1 /var/ossec/custom-script/trivy_scan.sh
   ```
3. **Check Wazuh Manager Logs:**
   ```bash
   echo "saeid12@" | sudo -S docker exec multi-node-wazuh.master-1 tail -f /var/ossec/logs/ossec.log | grep -i "trivy"
   ```

### Expected Outcome:
- **Dashboard:** Search for `rule.id:(100202 OR 100203 OR 100204 OR 100205 OR 100206)`.
- You should see alerts with severity labels like `CRITICAL`, `HIGH`, or `MEDIUM` for the `nginx:1.19.0` image.

---

## 2. Beelzebub (AI-Powered Honeypot)

Beelzebub simulates a Linux system and WordPress site to attract and analyze attackers.

### Steps to Test (SSH):
1. **Connect to the Honeypot (Port 2222):**
   ```bash
   ssh root@localhost -p 2222
   ```
2. **Enter any password** (e.g., `admin`, `123456`).
3. **Execute Commands:** Try `ls`, `whoami`, `uname -a`.

### Steps to Test (HTTP):
1. **Access the Fake WordPress Site:**
   ```bash
   curl http://localhost:8000/
   ```
2. **Attempt to Access Admin:**
   ```bash
   curl http://localhost:8000/wp-admin
   ```

### Expected Outcome:
- **Dashboard:** Filter by Rule IDs `110000-110003`.
- You will see "Beelzebub: Honeypot session established" and "Command executed" alerts.

---

## 3. Cowrie (SSH/Telnet Honeypot)

Cowrie is a medium-interaction honeypot designed to log brute force attacks and shell interaction.

### Steps to Test:
1. **Connect to Cowrie (Port 2223):**
   ```bash
   ssh root@localhost -p 2223
   ```
2. **Enter any password.**
3. **Perform Interactions:** Run commands or try to upload a file (if supported by your client).

### Expected Outcome:
- **Dashboard:** Filter by Rule IDs `120000-120003`.
- You should see alerts for "New SSH/Telnet connection", "Successful login", and "Command executed".

---

## 📈 Verification Checklist

| Component | Test Action | Expected Rule ID(s) | Status |
| :--- | :--- | :--- | :--- |
| **Trivy** | Manual Scan | 100202 - 100206 | [ ] |
| **Beelzebub** | SSH Login / Commands | 110001, 110002 | [ ] |
| **Cowrie** | SSH Login / Commands | 120001, 120002 | [ ] |

---
> [!TIP]
> To see raw alerts in real-time for ALL components, run:
> `echo "saeid12@" | sudo -S docker exec multi-node-wazuh.master-1 tail -f /var/ossec/logs/alerts/alerts.json | grep -E "trivy|beelzebub|cowrie"`
