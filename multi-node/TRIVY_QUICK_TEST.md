# Quick Test Commands for Trivy Integration

## 1. Run Manual Scan (Quick Test)
```bash
echo "saeid12@" | sudo -S docker exec multi-node-wazuh.master-1 /var/ossec/custom-script/trivy_scan.sh | head -20
```

## 2. Check if Scan is Working
```bash
# See first 20 lines of scan output
echo "saeid12@" | sudo -S docker exec multi-node-wazuh.master-1 bash -c "timeout 60 /var/ossec/custom-script/trivy_scan.sh 2>&1 | head -20"
```

## 3. View Trivy Alerts in Wazuh Dashboard
- URL: `https://172.25.0.222` (or your VIP)
- Go to: **Security Events** → **Events**
- Filter by: `rule.id:(100202 OR 100203 OR 100204 OR 100205 OR 100206)`

## 4. Check Wazuh Logs for Trivy Activity
```bash
# Real-time monitoring
echo "saeid12@" | sudo -S docker exec multi-node-wazuh.master-1 tail -f /var/ossec/logs/ossec.log | grep -i trivy

# Last 100 lines
echo "saeid12@" | sudo -S docker exec multi-node-wazuh.master-1 tail -100 /var/ossec/logs/ossec.log | grep -i trivy
```

## 5. Test with Known Vulnerable Image
```bash
# Pull an older vulnerable image
echo "saeid12@" | sudo -S docker pull nginx:1.19.0

# Run scan
echo "saeid12@" | sudo -S docker exec multi-node-wazuh.master-1 /var/ossec/custom-script/trivy_scan.sh | grep "nginx:1.19.0"
```

## 6. Verify Wodle Configuration
```bash
echo "saeid12@" | sudo -S docker exec multi-node-wazuh.master-1 grep -A 10 "Trivy container vulnerability" /var/ossec/etc/ossec.conf
```

## 7. Check Rule Loading
```bash
# Verify rules are loaded
echo "saeid12@" | sudo -S docker exec multi-node-wazuh.master-1 grep -r "100202\|100203\|100204" /var/ossec/etc/rules/
```

## Expected Output Format
```
Trivy:"nginx:stable","curl","7.68.0","CVE-2023-38545","HIGH","curl vulnerability description"
Trivy:"wazuh/wazuh-manager:4.14.1","openssl","1.1.1","CVE-2023-XXXXX","CRITICAL","OpenSSL vulnerability"
```

## Alert Rule IDs
- **100202**: CRITICAL severity (Level 14)
- **100203**: HIGH severity (Level 12)
- **100204**: MEDIUM severity (Level 7)
- **100205**: LOW severity (Level 4)
- **100206**: UNKNOWN severity (Level 7)

## Troubleshooting
```bash
# Check Trivy version
echo "saeid12@" | sudo -S docker exec multi-node-wazuh.master-1 /usr/local/bin/trivy --version

# Check Docker connectivity
echo "saeid12@" | sudo -S docker exec multi-node-wazuh.master-1 docker ps

# Check script permissions
echo "saeid12@" | sudo -S docker exec multi-node-wazuh.master-1 ls -l /var/ossec/custom-script/trivy_scan.sh
```
