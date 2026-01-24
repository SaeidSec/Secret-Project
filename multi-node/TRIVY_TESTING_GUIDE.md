# Trivy Integration Testing Guide

## Prerequisites
- Wazuh Manager is running with Trivy integration configured
- Docker socket is mounted to the Wazuh Manager container
- You have access to the Wazuh Dashboard

## Testing Methods

### Method 1: Manual Scan Execution
Run a manual scan to test immediately:

```bash
# Execute the Trivy scan script manually
echo "saeid12@" | sudo -S docker exec multi-node-wazuh.master-1 /var/ossec/custom-script/trivy_scan.sh
```

**Expected Output:**
- Lines starting with `Trivy:"<image_name>",<package>,<version>,<vulnerability_id>,<severity>,<description>`
- Example: `Trivy:"nginx:stable","curl","7.68.0-1ubuntu2.18","CVE-2023-38545","HIGH","curl vulnerability"`

### Method 2: Check Wazuh Logs
Monitor the Wazuh Manager logs for Trivy-related activity:

```bash
# Check for Trivy command execution
echo "saeid12@" | sudo -S docker compose logs wazuh.master | grep -i "trivy"

# Check for Trivy alerts in ossec.log
echo "saeid12@" | sudo -S docker exec multi-node-wazuh.master-1 tail -f /var/ossec/logs/ossec.log | grep -i "trivy"
```

### Method 3: Verify File Mounts
Confirm all required files are properly mounted:

```bash
echo "saeid12@" | sudo -S docker exec multi-node-wazuh.master-1 bash -c "
  echo '=== Checking Trivy Binary ==='
  ls -lh /usr/local/bin/trivy
  
  echo -e '\n=== Checking Docker Binary ==='
  ls -lh /usr/bin/docker
  
  echo -e '\n=== Checking Scan Script ==='
  ls -lh /var/ossec/custom-script/trivy_scan.sh
  
  echo -e '\n=== Checking Decoders ==='
  ls -lh /var/ossec/etc/decoders/trivy_decoders.xml
  
  echo -e '\n=== Checking Rules ==='
  ls -lh /var/ossec/etc/rules/trivy_rules.xml
  
  echo -e '\n=== Testing Docker Socket ==='
  docker ps --format '{{.Names}}' | head -5
"
```

### Method 4: Check Wazuh Dashboard
1. Open the Wazuh Dashboard: `https://172.25.0.222` (or your configured VIP)
2. Navigate to **Security Events** or **Threat Hunting**
3. Search for Trivy alerts using the query:
   ```
   rule.id:(100202 OR 100203 OR 100204 OR 100205 OR 100206)
   ```
4. You should see alerts with:
   - **Rule ID 100202**: CRITICAL vulnerabilities
   - **Rule ID 100203**: HIGH vulnerabilities
   - **Rule ID 100204**: MEDIUM vulnerabilities
   - **Rule ID 100205**: LOW vulnerabilities
   - **Rule ID 100206**: UNKNOWN severity vulnerabilities

### Method 5: Test with a Vulnerable Image
Pull and scan a known vulnerable image:

```bash
# Pull a vulnerable image (older nginx version)
echo "saeid12@" | sudo -S docker pull nginx:1.19.0

# Wait a moment, then trigger a manual scan
echo "saeid12@" | sudo -S docker exec multi-node-wazuh.master-1 /var/ossec/custom-script/trivy_scan.sh

# Check the output for vulnerabilities
```

### Method 6: Verify Wodle Configuration
Check that the command module is properly configured:

```bash
echo "saeid12@" | sudo -S docker exec multi-node-wazuh.master-1 grep -A 10 "Trivy container vulnerability" /var/ossec/etc/ossec.conf
```

**Expected Output:**
```xml
<!-- Trivy container vulnerability scanner script -->
<wodle name="command">
  <disabled>no</disabled>
  <command>/var/ossec/custom-script/trivy_scan.sh</command>
  <interval>3d</interval>
  <ignore_output>no</ignore_output>
  <run_on_start>yes</run_on_start>
  <timeout>0</timeout>
</wodle>
```

## Troubleshooting

### Issue: No output from scan
**Solution:**
```bash
# Check if Trivy can access Docker
echo "saeid12@" | sudo -S docker exec multi-node-wazuh.master-1 docker ps

# Check if Trivy binary is executable
echo "saeid12@" | sudo -S docker exec multi-node-wazuh.master-1 /usr/local/bin/trivy --version
```

### Issue: Permission denied on Docker socket
**Solution:**
```bash
# Verify Docker socket is mounted
echo "saeid12@" | sudo -S docker exec multi-node-wazuh.master-1 ls -l /var/run/docker.sock

# Check socket permissions
echo "saeid12@" | sudo -S docker exec multi-node-wazuh.master-1 stat /var/run/docker.sock
```

### Issue: No alerts in Dashboard
**Solution:**
1. Verify rules are loaded:
   ```bash
   echo "saeid12@" | sudo -S docker exec multi-node-wazuh.master-1 /var/ossec/bin/wazuh-logtest
   # Then paste a sample Trivy output line
   ```
2. Check rule files exist and have correct permissions
3. Restart Wazuh Manager if needed

## Expected Timeline
- **First scan**: 5-15 minutes (Trivy downloads vulnerability database)
- **Subsequent scans**: 1-5 minutes (depending on number of images)
- **Alert appearance**: Within 1-2 minutes after scan completes

## Success Indicators
✅ Trivy scan script executes without errors
✅ Output contains vulnerability data in expected format
✅ Alerts appear in Wazuh Dashboard with rule IDs 100202-100206
✅ Alerts contain image name, package, version, and CVE information
✅ Scheduled scans run automatically every 3 days
