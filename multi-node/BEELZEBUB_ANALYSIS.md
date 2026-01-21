# 🐝 Beelzebub Honeypot: Integration Analysis & Strategy

## 1. Executive Summary
Beelzebub is a "low-code" honeypot framework that stands out by using AI (LLMs) to simulate high-interaction systems (like a real Ubuntu terminal) while remaining a low-interaction, secure decoy. Integrating this into our Wazuh SIEM significantly enhances our **Threat Intelligence** and **Early Warning** capabilities.

## 2. Key Capabilities
- **AI Virtualization:** Uses LLMs (OpenAI, Ollama) to generate realistic responses to attacker commands (e.g., `ls`, `cat /etc/passwd`, `docker ps`).
- **Multi-Protocol:** Supports SSH, HTTP, and MCP (Model Context Protocol).
- **Security:** Written in Go, designed for speed and security. It separates the decoy services from the core engine.
- **Observability:** Provides Prometheus metrics and structured logging.

## 3. Integration Architecture

### Layer 1: Data Collection (The Decoy)
Beelzebub will run as a dedicated Docker container on the `multi-node_wazuh-net` network. It will be "exposed" to the network to attract attackers.

### Layer 2: Log Forwarding
Beelzebub generates structured JSON logs. We have two options for integration:
1. **Wazuh Agent Sidecar:** Run a Wazuh Agent in the same network or as a sidecar to monitor the Beelzebub log files.
2. **Direct Syslog/Fluent-bit:** Forward Beelzebub logs to the Wazuh Manager over the network.
*Decision:* We will use a **Wazuh Agent** (or mount the Beelzebub log volume to the Wazuh Manager) to ingest the logs directly for maximum reliability.

### Layer 3: Rule Matching & Alerting
We will create custom Wazuh decoders and rules to:
- Detect successful "logins" to the honeypot.
- Identify specific commands run by attackers (extracted from Beelzebub JSON).
- Alert on specific patterns like "Prompt Injection" against the AI honeypot.

## 4. Implementation Strategy

### Stage 1: Configuration
- Define `beelzebub.yaml` with a mix of SSH and HTTP decoys.
- Setup a "Cowrie-like" SSH service on port 22 and a "Wordpress" HTTP service on port 80.

### Stage 2: Orchestration
- Add `beelzebub` service to `docker-compose.yml`.
- Ensure it sits on the `wazuh-net` but is logically isolated if possible.

### Stage 3: Wazuh Integration
- Update `ossec.conf` on the Wazuh Manager to monitor Beelzebub logs.
- Map Beelzebub fields (attacker IP, protocol, command, status) to Wazuh fields.
- Create a Grafana dashboard specifically for Honeypot activity.

## 5. Risk Assessment
- **Escalation:** Beelzebub is low-interaction, so the risk of an attacker "breaking out" of the honeypot into the host is minimal.
- **Resource Usage:** If LLM features are used with local Ollama, high RAM/CPU is required. We will stick to static responses or remote OpenAI API for the initial integration to keep it "lightweight".

---
*Prepared by antigravity for SaeidSec's Enterprise Wazuh Project.*
