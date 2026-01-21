# 🐝 Beelzebub Honeypot: Simulation & Testing Guide

This guide provides scenarios to test the Beelzebub honeypot integration and verify that Wazuh is correctly alerting on "malicious" activity.

## 1. Prerequisites
Ensure the stack is running:
```bash
docker compose up -d beelzebub wazuh.master
```

## 2. Scenario A: SSH Intrusion
Beelzebub is listening on **Port 2222** (mapped from its internal port 22).

### Simulation Steps:
1. **Connect to the Honeypot:**
   ```bash
   ssh root@localhost -p 2222
   ```
2. **Enter a "Compromised" Password:**
   Use any of these: `123456`, `password`, `admin`, `qwerty`.
3. **Execute Commands:**
   Once "logged in", try these commands:
   ```bash
   ls
   whoami
   pwd
   uname -a
   docker ps
   ```

### Expected Outcome:
- **Beelzebub:** Will provide realistic (but fake) terminal output.
- **Wazuh Alert:** Rule `110001` (Session established) followed by multiple `110002` (Command executed) alerts.

---

## 3. Scenario B: Web Application Reconnaissance
Beelzebub is simulating a WordPress site on **Port 8000** (mapped from its internal port 80).

### Simulation Steps:
1. **Browse the Site:**
   ```bash
   curl http://localhost:8000/
   ```
2. **Attempt to Access Admin Panel:**
   ```bash
   curl http://localhost:8000/wp-admin
   ```
3. **Simulate a Web Scan:**
   ```bash
   curl http://localhost:8000/random-admin-path
   ```

### Expected Outcome:
- **Beelzebub:** Returns a fake WordPress landing page or login form.
- **Wazuh Alert:** JSON logs will be ingested. You should see "HoneyPot event" in the security archives.

---

## 4. Verification in Wazuh

### Method 1: Wazuh Dashboard (Recommended)
1. Go to **Security Events**.
2. Filter by Rule ID: `110000-110003`.
3. You will see the timeline of the "attack", including the IP address of the simulation and the commands run.

### Method 2: Command Line (Manager Logs)
Run this on the host to see raw alerts in real-time:
```bash
docker exec -it wazuh.master tail -f /var/ossec/logs/alerts/alerts.json | grep beelzebub
```

---
> [!TIP]
> Since we used a shared volume, logs are written to `beelzebub-logs` and read by Wazuh instantly. There is no need for a standard agent in this specific architecture!
