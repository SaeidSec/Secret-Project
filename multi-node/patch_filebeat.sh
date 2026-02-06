#!/bin/bash
# 🛠️ Wazuh Filebeat 9.3.0 Patch Automation Script
# This script enables OpenSearch 2.x compatibility for Wazuh 4.14.x

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

DBIN_DIR="./filebeat-9.3.0/bin"
IMAGE="docker.elastic.co/beats/filebeat:9.3.0"

echo "🚀 Starting Filebeat 9.3.0 Patch for OpenSearch compatibility..."

# 1. Create directory structure
mkdir -p "$DBIN_DIR"

# 2. Pull and extract Filebeat binary
if [ ! -f "$DBIN_DIR/filebeat.real" ]; then
    echo "📥 Pulling Filebeat image to extract binary..."
    docker pull "$IMAGE"
    echo "📦 Extracting binary..."
    ID=$(docker create "$IMAGE")
    docker cp "$ID":/usr/share/filebeat/filebeat "$DBIN_DIR/filebeat.real"
    docker rm -v "$ID"
    chmod +x "$DBIN_DIR/filebeat.real"
fi

# 3. Create Filebeat Wrapper Script
echo "📜 Creating Filebeat Wrapper Script..."
cat << 'EOF' > "$DBIN_DIR/filebeat"
#!/bin/bash
FILEBEAT_BIN="/usr/share/filebeat/bin/filebeat.real"
FB_CONFIG="/etc/filebeat/filebeat.yml"

# 1. Modify filebeat.yml on the fly
# Point to the wazuh-proxy container securely
sed -i "s|https://wazuh.vip:9200|https://wazuh-proxy:9201|g" "$FB_CONFIG"

# Disable template management as per requirement
sed -i "s|setup.template.json.enabled:.*|setup.template.json.enabled: false|g" "$FB_CONFIG"
sed -i "s|setup.template.overwrite:.*|setup.template.overwrite: false|g" "$FB_CONFIG"
if ! grep -q "setup.template.enabled:" "$FB_CONFIG"; then
    echo "setup.template.enabled: false" >> "$FB_CONFIG"
else
    sed -i "s|setup.template.enabled:.*|setup.template.enabled: false|g" "$FB_CONFIG"
fi
sed -i "s|setup.ilm.enabled:.*|setup.ilm.enabled: false|g" "$FB_CONFIG"

# ENFORCE SSL Verification (Production Security)
# We now require full verification because wazuh-proxy is a proper service with certs
# Note: wazuh-proxy typically uses the same certs as wazuh.master for simplicity in this bridge,
# or we can rely on the CA trusting it.
# For now, we set it to 'full' and point to the CA.
sed -i "s|ssl.verification_mode: 'none'|ssl.verification_mode: 'full'|g" "$FB_CONFIG"

# Ensure CA and Certs are correctly referenced if they aren't already
# (The docker-compose mounts these to /etc/ssl/, and filebeat.yml usually expects them there)
# If the original filebeat.yml had specific paths, we might need to adjust them, 
# but usually wazuh-docker config key/cert paths are standard.
# We'll explicitly set them just in case.

if ! grep -q "ssl.certificate_authorities" "$FB_CONFIG"; then
    echo "ssl.certificate_authorities: ['/etc/ssl/root-ca.pem']" >> "$FB_CONFIG"
    echo "ssl.certificate: '/etc/ssl/filebeat.pem'" >> "$FB_CONFIG"
    echo "ssl.key: '/etc/ssl/filebeat.key'" >> "$FB_CONFIG"
fi

# 2. Translate arguments (-path.* to --path.*)
declare -a args
for arg in "$@"; do
    case "$arg" in
        -path.home) args+=("--path.home") ;;
        -path.config) args+=("--path.config") ;;
        -path.data) args+=("--path.data") ;;
        -path.logs) args+=("--path.logs") ;;
        *) args+=("$arg") ;;
    esac
done

exec "$FILEBEAT_BIN" "${args[@]}"
EOF
chmod +x "$DBIN_DIR/filebeat"

echo "✅ Filebeat 9.3.0 Patch prepared successfully (Proxy Mode: External Microservice)!"
