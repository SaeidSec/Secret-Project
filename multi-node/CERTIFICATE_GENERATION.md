# 🔐 Certificate Generation Guide

Complete guide for generating and managing SSL/TLS certificates for Wazuh deployment.

## Overview

The Wazuh stack requires SSL/TLS certificates for secure communication between:
- Wazuh Indexers (OpenSearch cluster)
- Wazuh Managers and Indexers
- Wazuh Dashboard and Indexers
- Admin access to Indexers

## Option 1: Self-Signed Certificates (Recommended for Testing)

### Quick Start

```bash
cd multi-node
docker compose -f generate-indexer-certs.yml run --rm generator
```

### Behind a Proxy

If your system uses a proxy, edit `generate-indexer-certs.yml`:

```yaml
services:
  generator:
    image: wazuh/wazuh-certs-generator:0.0.3
    hostname: wazuh-certs-generator
    volumes:
      - ./config/wazuh_indexer_ssl_certs/:/certificates/
      - ./config/certs.yml:/config/certs.yml
    environment:
      - HTTP_PROXY=http://your-proxy:port
      - HTTPS_PROXY=http://your-proxy:port
```

### Certificate Configuration

The certificate generator uses `config/certs.yml` to define nodes:

```yaml
nodes:
  indexer:
    - name: wazuh1.indexer
      ip: wazuh1.indexer
    - name: wazuh2.indexer
      ip: wazuh2.indexer
    - name: wazuh3.indexer
      ip: wazuh3.indexer

  server:
    - name: wazuh.master
      ip: wazuh.master
      node_type: master
    - name: wazuh.worker
      ip: wazuh.worker
      node_type: worker

  dashboard:
    - name: wazuh.dashboard
      ip: wazuh.dashboard
```

### Generated Certificates

After generation, you'll have these files in `config/wazuh_indexer_ssl_certs/`:

**Indexer Certificates:**
- `root-ca.pem` - Root CA certificate
- `wazuh1.indexer.pem` / `wazuh1.indexer-key.pem`
- `wazuh2.indexer.pem` / `wazuh2.indexer-key.pem`
- `wazuh3.indexer.pem` / `wazuh3.indexer-key.pem`
- `admin.pem` / `admin-key.pem` - Admin access

**Manager Certificates:**
- `root-ca-manager.pem` - Manager CA certificate
- `wazuh.master.pem` / `wazuh.master-key.pem`
- `wazuh.worker.pem` / `wazuh.worker-key.pem`

**Dashboard Certificates:**
- `wazuh.dashboard.pem` / `wazuh.dashboard-key.pem`

## Option 2: Your Own Certificates

### Requirements

- Valid SSL/TLS certificates from a trusted CA (Let's Encrypt, commercial CA, or internal PKI)
- Certificates must match the hostnames/IPs in your deployment
- PEM format required

### File Naming Convention

Place your certificates in `multi-node/config/wazuh_indexer_ssl_certs/` with these exact names:

**Wazuh Indexer:**
```
root-ca.pem
wazuh1.indexer.pem
wazuh1.indexer-key.pem
wazuh2.indexer.pem
wazuh2.indexer-key.pem
wazuh3.indexer.pem
wazuh3.indexer-key.pem
admin.pem
admin-key.pem
```

**Wazuh Manager:**
```
root-ca-manager.pem
wazuh.master.pem
wazuh.master-key.pem
wazuh.worker.pem
wazuh.worker-key.pem
```

**Wazuh Dashboard:**
```
wazuh.dashboard.pem
wazuh.dashboard-key.pem
root-ca.pem (same as indexer CA)
```

### Using Let's Encrypt

```bash
# Install certbot
sudo apt install certbot

# Generate certificates
sudo certbot certonly --standalone -d wazuh.yourdomain.com

# Copy certificates
sudo cp /etc/letsencrypt/live/wazuh.yourdomain.com/fullchain.pem \
  multi-node/config/wazuh_indexer_ssl_certs/wazuh.dashboard.pem

sudo cp /etc/letsencrypt/live/wazuh.yourdomain.com/privkey.pem \
  multi-node/config/wazuh_indexer_ssl_certs/wazuh.dashboard-key.pem

# Set permissions
sudo chown -R $USER:$USER multi-node/config/wazuh_indexer_ssl_certs/
chmod 644 multi-node/config/wazuh_indexer_ssl_certs/*.pem
chmod 600 multi-node/config/wazuh_indexer_ssl_certs/*-key.pem
```

## Certificate Verification

### Check Certificate Details

```bash
# View certificate
openssl x509 -in config/wazuh_indexer_ssl_certs/wazuh1.indexer.pem -text -noout

# Verify certificate and key match
openssl x509 -noout -modulus -in config/wazuh_indexer_ssl_certs/wazuh1.indexer.pem | openssl md5
openssl rsa -noout -modulus -in config/wazuh_indexer_ssl_certs/wazuh1.indexer-key.pem | openssl md5
# The MD5 hashes should match
```

### Test SSL Connection

```bash
# Test indexer SSL
openssl s_client -connect localhost:9200 -CAfile config/wazuh_indexer_ssl_certs/root-ca.pem

# Test dashboard SSL
openssl s_client -connect localhost:443 -CAfile config/wazuh_indexer_ssl_certs/root-ca.pem
```

## Certificate Rotation

### When to Rotate

- Certificates expiring within 30 days
- Security breach or key compromise
- Regular security policy (e.g., annually)

### Rotation Procedure

1. **Generate new certificates:**
```bash
# Backup old certificates
cp -r config/wazuh_indexer_ssl_certs config/wazuh_indexer_ssl_certs.backup

# Generate new certificates
docker compose -f generate-indexer-certs.yml run --rm generator
```

2. **Update running services:**
```bash
# Restart indexers one at a time
docker restart wazuh1.indexer
sleep 30
docker restart wazuh2.indexer
sleep 30
docker restart wazuh3.indexer

# Restart managers
docker restart wazuh.master wazuh.worker

# Restart dashboard
docker restart wazuh.dashboard
```

3. **Verify cluster health:**
```bash
curl -k -u admin:SecretPassword https://localhost:9200/_cluster/health?pretty
```

## Troubleshooting

### Certificate Permission Errors

```bash
# Fix permissions
sudo chown -R $USER:$USER config/wazuh_indexer_ssl_certs/
chmod 644 config/wazuh_indexer_ssl_certs/*.pem
chmod 600 config/wazuh_indexer_ssl_certs/*-key.pem
```

### Certificate Verification Failed

```bash
# Check certificate validity
openssl x509 -in config/wazuh_indexer_ssl_certs/wazuh1.indexer.pem -noout -dates

# Verify CA chain
openssl verify -CAfile config/wazuh_indexer_ssl_certs/root-ca.pem \
  config/wazuh_indexer_ssl_certs/wazuh1.indexer.pem
```

### Indexer Won't Start

```bash
# Check logs for SSL errors
docker logs wazuh1.indexer | grep -i ssl

# Common issues:
# - Certificate/key mismatch
# - Wrong file permissions
# - Expired certificates
# - Incorrect file paths in docker-compose.yml
```

## Security Best Practices

1. **Never commit private keys to git:**
   - Add `*.pem` to `.gitignore`
   - Use secrets management for production

2. **Use strong key sizes:**
   - Minimum 2048-bit RSA
   - Prefer 4096-bit for production

3. **Set proper permissions:**
   ```bash
   chmod 644 *.pem      # Certificates
   chmod 600 *-key.pem  # Private keys
   ```

4. **Regular rotation:**
   - Rotate certificates before expiration
   - Maintain certificate inventory

5. **Secure storage:**
   - Backup certificates securely
   - Encrypt backups
   - Limit access to certificate files

## Production Recommendations

For production deployments:

1. **Use certificates from a trusted CA** (Let's Encrypt, DigiCert, etc.)
2. **Implement certificate monitoring** to track expiration
3. **Automate certificate renewal** (e.g., certbot with cron)
4. **Use Hardware Security Modules (HSM)** for key storage
5. **Maintain certificate inventory** and documentation
6. **Test certificate rotation** in staging environment first

---

**Need Help?** Check the [Wazuh documentation](https://documentation.wazuh.com/) or open an issue on GitHub.
