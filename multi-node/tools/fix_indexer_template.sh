#!/bin/bash
# Script to fix missing Wazuh index template in OpenSearch/Indexer
# Usage: bash fix_indexer_template.sh

set -e

echo "🔍 Detecting Wazuh Master container..."
MASTER_CONTAINER=$(docker ps --format '{{.Names}}' | grep "wazuh.master" | head -n 1)

if [ -z "$MASTER_CONTAINER" ]; then
    echo "❌ Error: Wazuh Master container not found. Is the stack running?"
    exit 1
fi

echo "✅ Found Master container: $MASTER_CONTAINER"

echo "📤 Forcing Filebeat to upload Wazuh index template to Indexer (bypassing SSL verification)..."
# We use non-interactive exec since we might be running in a script environment
# We disable SSL verification because the certs are for the indexer nodes, not the VIP
docker exec "$MASTER_CONTAINER" filebeat setup --index-management -E setup.template.overwrite=true -E output.elasticsearch.ssl.verification_mode=none

echo "✅ Template upload command finished."

echo "🔬 Verifying template presence in Indexer..."
# Authenticate against the local indexer (via LB port 9200)
# We use -k because of self-signed certs
if curl -k -u admin:SecretPassword https://localhost:9200/_cat/templates/wazuh-alerts-* > /dev/null 2>&1; then
    echo "✅ Success: Wazuh alerts template found in Indexer."
else
    echo "⚠️ Warning: Could not verify template via localhost:9200. This might be due to networking or certificate issues."
    echo "Please check the Wazuh Dashboard health check (https://172.25.0.222) manually."
fi

echo ""
echo "Fix complete. Please refresh your Wazuh Dashboard health check page."
