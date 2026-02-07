# Wazuh Proxy Microservice

The refactoring of the OpenSearch compatibility gateway (the **wazuh-proxy**) from a legacy script into a production-grade microservice introduces several significant strengths while addressing the critical vulnerabilities of the previous implementation.

## 🚀 Project Strengths

*   **Zero-Trust Security Framework:** The new architecture implements **Mutual TLS (mTLS)**, requiring client certificates for every connection, which prevents unauthorized devices from injecting data. It also enforces **upstream verification**, ensuring the proxy only communicates with a verified OpenSearch cluster to prevent Man-in-the-Middle (MitM) attacks.
*   **High Performance and Scalability:** By moving to a **FastAPI/Uvicorn** stack with **Asynchronous I/O**, the microservice can handle thousands of concurrent requests with a minimal memory footprint. This design eliminates the thread exhaustion issues found in the legacy blocking model. Furthermore, the microservice can **scale horizontally** to support massive ingestion throughput.
*   **Granular Policy Enforcement:** The proxy acts as a security gatekeeper by using middleware to **filter HTTP methods**. It permits only safe ingestion verbs (GET, POST, PUT, HEAD) and explicitly **blocks destructive commands** like `DELETE` or access to sensitive cluster settings.
*   **Backend Resilience:** Integrated **rate limiting** (using a token-bucket algorithm) protects the storage backend from "ingestion storms" or denial-of-service (DoS) attempts by throttling requests per client IP.
*   **Improved Observability:** Unlike the legacy script's unstructured output, the new system uses **structured JSON logging** with timestamps and severity levels, allowing for effective auditing and debugging of distributed failures.

## ⚠️ Project Weaknesses

While the new architecture fixes many legacy issues, some inherent challenges remain:

*   **Complexity of Infrastructure:** The shift to a hardened production environment requires a robust **Internal Certificate Authority (CA)** to manage, sign, and distribute certificates for mTLS. This increases the operational overhead compared to simpler, less secure setups.
*   **Configuration Sensitivity:** The security of the system depends on strict client-side configuration. For example, Filebeat must be manually reconfigured to use "full" SSL verification and the correct internal certificates; failure to do so correctly would break the ingestion pipeline.
*   **Single Point of Policy Management:** While centralized control is a benefit, it also means that any misconfiguration in the proxy's filtering or rate-limiting policies could inadvertently block legitimate security data across the entire ecosystem.

## 🛠️ Legacy Context (Fixed Vulnerabilities)

The original version suffered from several critical issues that motivated this refactoring:
*   **Blocking I/O:** Caused latency spikes and system failure under high load.
*   **Lack of Authentication:** No form of authentication or request filtering was present.
*   **Security Risk:** A compromised frontend could theoretically delete the entire database due to lack of verb filtering.
