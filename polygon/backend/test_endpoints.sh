#!/bin/bash
BASE="https://metabolous-deirdre-wriggliest.ngrok-free.dev"

echo "1. Registering Beekeeper..."
BEEKEEPER=$(curl -s -X POST $BASE/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Tester Beekeeper","role":"beekeeper","password":"testpassword","region":"Test Region"}')
BEEKEEPER_ID=$(echo $BEEKEEPER | python3 -c "import sys,json; print(json.load(sys.stdin).get('id', 'FAILED'))")
echo "Beekeeper ID: $BEEKEEPER_ID"

echo "2. Logging in..."
TOKEN=$(curl -s -X POST $BASE/auth/login \
  -H "Content-Type: application/json" \
  -d '{"name":"Tester Beekeeper","password":"testpassword"}' | python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token', 'FAILED'))")
echo "Token: ${TOKEN:0:10}..."

echo "3. Registering Hive..."
HIVE=$(curl -s -X POST $BASE/hive/ \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"beekeeper_id\":\"$BEEKEEPER_ID\",\"device_id\":\"ESP32-TEST\",\"region_public\":\"Test Region\"}")
HIVE_ID=$(echo $HIVE | python3 -c "import sys,json; print(json.load(sys.stdin).get('id', 'FAILED'))")
echo "Hive ID: $HIVE_ID"

echo "4. Pushing Sensor Data..."
SENSOR=$(curl -s -X POST $BASE/hive/sensor-data \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"hive_id\":\"$HIVE_ID\",\"ts\":\"2026-09-13T10:00:00\",\"temperature_c\":34.2,\"humidity_pct\":61.8,\"weight_kg\":27.35,\"is_simulated\":true}")
echo "Sensor Data Result: $SENSOR"

echo "5. Creating Harvest..."
HARVEST=$(curl -s -X POST $BASE/harvest \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"hive_id\":\"$HIVE_ID\",\"harvest_date\":\"2026-09-13T08:00:00\",\"quantity_g\":1000,\"floral_source\":\"Test Flora\"}")
HARVEST_ID=$(echo $HARVEST | python3 -c "import sys,json; print(json.load(sys.stdin).get('id', 'FAILED'))")
echo "Harvest ID: $HARVEST_ID"

echo "6. Creating Blockchain Batch..."
BATCH=$(curl -s -X POST $BASE/batch \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"batch_code\":\"HC-TEST-001\",\"harvest_id\":\"$HARVEST_ID\",\"honey_type\":\"Test Flora\",\"region\":\"Test Region\"}")
TX=$(echo $BATCH | python3 -c "import sys,json; print(json.load(sys.stdin).get('create_tx_hash', 'FAILED'))")
echo "Transaction Hash: $TX"

