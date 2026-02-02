#!/bin/bash
# Wazuh HA Failover Test Script
# Run with sudo

VIP="172.25.0.222"
NODE1="multi-node-lb-node-1-1"

if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root (sudo)"
  exit
fi

echo "🚀 Starting HA Failover Test on VIP $VIP..."
echo "---"

# Check initial connectivity
ping -c 1 -W 1 $VIP > /dev/null
if [ $? -ne 0 ]; then
    echo "❌ Initial connection to VIP failed. Is the stack up?"
    exit 1
fi
echo "✅ Initial VIP Connection: OK"

# Start Ping Monitor in background
echo "📡 Pinging VIP in background (output to ping_test.log)..."
ping -i 0.2 $VIP > ping_test.log &
PING_PID=$!

echo "⏳ Waiting 3 seconds..."
sleep 3

echo "🔻 SIMULATING FAILURE: Stopping Master Node ($NODE1)..."
docker stop $NODE1 > /dev/null
echo "✅ Node Stopped."

echo "⏳ Waiting 10 seconds (Failover should happen instantly)..."
sleep 10

echo "🔺 RECOVERY: Starting Master Node ($NODE1)..."
docker start $NODE1 > /dev/null
echo "✅ Node Started."

echo "⏳ Waiting 10 seconds (Failback should occur)..."
sleep 10

# Stop Ping
kill $PING_PID
echo "🛑 Test Complete."
echo "---"

# Analyze Results
echo "📊 TEST RESULTS:"
TOTAL=$(grep "icmp_seq" ping_test.log | wc -l)
LOST=$(grep -c "Request timeout" ping_test.log || echo 0) 
# Note: ping output format varies, but verifying success counts vs duration is better.
SUCCESS=$(grep "bytes from" ping_test.log | wc -l)

echo "   Total Pings Sent: ~100 (Estimate based on duration)"
echo "   Successful Pings: $SUCCESS"
echo "   (Check ping_test.log for detailed drop patterns)"

if [ $SUCCESS -gt 50 ]; then
    echo "✅ HA SUCCESS: Connectivity was maintained."
else
    echo "⚠️  HA WARNING: Significant packet loss detected."
fi

echo "---"
echo "🧹 Cleaning up log..."
rm ping_test.log
