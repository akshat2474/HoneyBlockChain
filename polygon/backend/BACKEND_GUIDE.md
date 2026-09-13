# HoneyChain Backend — Developer Guide

> **TL;DR:** Install Python deps, create a PostgreSQL database, run one Alembic migration, then `uvicorn`. Everything else is automatic.

---

## Table of Contents

1. [Architecture overview](#1-architecture-overview)
2. [One-time setup](#2-one-time-setup)
3. [Running the server](#3-running-the-server)
4. [All API endpoints](#4-all-api-endpoints)
5. [End-to-end demo walkthrough](#5-end-to-end-demo-walkthrough)
6. [QR verification flow explained](#6-qr-verification-flow-explained)
7. [Running the tests](#7-running-the-tests)
8. [AI team — how to plug in the real model](#8-ai-team--how-to-plug-in-the-real-model)
9. [IoT / MQTT explained](#9-iot--mqtt-explained)
10. [Troubleshooting](#10-troubleshooting)
11. [Flutter team — API contract](#11-flutter-team--api-contract)

---

## 1. Architecture Overview

```
Flutter App  ──POST JSON──►  FastAPI Backend (port 8000)
                                  │
              ┌───────────────────┼────────────────────────┐
              │                   │                        │
        PostgreSQL          Polygon Amoy              Pinata IPFS
        (operational       (immutable ledger)       (metadata CID)
         records,
         scan analytics,
         custody history)
              │
        MQTT Broker ◄── ESP32 sensors  (background thread, auto-starts)
```

**Why three stores?**

| Store | What lives here | Why |
|---|---|---|
| PostgreSQL | Actors, hives, harvests, batches, custody events, QR scans | Fast queries, relational joins, business logic |
| Polygon Amoy | Batch hash, IPFS CID, metadata hash, lab cert hash, custody events | Immutable, publicly verifiable by judges & consumers |
| IPFS (Pinata) | Full metadata JSON (honey type, region, IoT summary, AI summary) | Too large/expensive to store on-chain; CID is a tamper-proof pointer |

**Request lifecycle for `POST /batch` (the main operation):**

```
Flutter sends batch_code + harvest_id
    │
    ▼
FastAPI validates JWT + BEEKEEPER_ROLE
    │
    ▼
Build metadata JSON (honey type, region, harvest info)
    │
    ▼
Upload JSON to Pinata → get CID + compute SHA-256 hash
    │
    ▼
Submit createBatch(batchIdHash, qty, timestamp, CID, hash32) to Polygon
    │
    ▼
Wait for tx_hash (Polygon mines the block ~2s on Amoy)
    │
    ▼
Save batch row to PostgreSQL
    │
    ▼
Generate HMAC-signed QR token
    │
    ▼
Return { tx_hash, CID, QR URL } to Flutter
```

---

## 2. One-Time Setup

### Step 1 — Create and activate a Python virtual environment

```bash
cd polygon/backend

# Remove the broken old venv first
rm -rf venv

# Create a fresh one
python3 -m venv venv
source venv/bin/activate
```

### Step 2 — Install all Python dependencies

```bash
pip install -r requirements.txt
```

This installs:

| Package | Purpose |
|---|---|
| `fastapi`, `uvicorn[standard]` | Web framework + ASGI server |
| `sqlalchemy`, `psycopg2-binary` | ORM + PostgreSQL driver |
| `alembic` | Database migrations |
| `python-jose[cryptography]` | JWT tokens |
| `passlib[bcrypt]` | Password hashing |
| `web3` | Polygon blockchain client |
| `requests` | Pinata IPFS uploads |
| `pydantic[email]` | Request/response validation |
| `paho-mqtt` | MQTT subscriber for ESP32 telemetry |
| `python-multipart` | File uploads (AI image endpoint) |
| `python-dotenv` | Load `.env` file |

### Step 3 — Set up PostgreSQL

If you don't have PostgreSQL installed:

```bash
# macOS
brew install postgresql@16
brew services start postgresql@16

# Ubuntu/Debian
sudo apt install postgresql
sudo service postgresql start
```

Create the database and user:

```bash
psql postgres
```

```sql
CREATE USER honeychain WITH PASSWORD 'honeychain';
CREATE DATABASE honeychain OWNER honeychain;
\q
```

> The `DATABASE_URL` in `.env` is already set to `postgresql://honeychain:honeychain@localhost:5432/honeychain` — this matches the credentials above.

### Step 4 — Run the database migration

```bash
cd polygon/backend
source venv/bin/activate
alembic upgrade head
```

Expected output:
```
INFO  [alembic.runtime.migration] Running upgrade  -> 001, Initial schema
```

This creates all 11 tables: `actors`, `beekeepers`, `hives`, `sensor_readings`, `harvests`, `batches`, `certificates`, `custody_events`, `ai_inferences`, `qr_tokens`, `qr_scans`.

### Step 5 — Verify your `.env`

The `.env` file in `polygon/backend/` already has the real keys filled in. Confirm these are set:

```
AMOY_RPC_URL="https://..."         ✓ already set
PRIVATE_KEY="..."                   ✓ already set
CONTRACT_ADDRESS="0x5BFA55..."      ✓ already set
PINATA_JWT="eyJ..."                 ✓ already set
DATABASE_URL="postgresql://..."     ✓ added
JWT_SECRET_KEY="..."                ✓ added
QR_HMAC_SECRET="..."                ✓ added
MQTT_HOST="localhost"               ✓ added
BACKEND_BASE_URL="http://localhost:8000"  ✓ added
```

---

## 3. Running the Server

```bash
cd polygon/backend
source venv/bin/activate
uvicorn app.main:app --reload --port 8000
```

You'll see:
```
INFO:     Uvicorn running on http://127.0.0.1:8000 (Press CTRL+C to quit)
INFO:honeychain.mqtt: MQTT subscriber thread started (broker=localhost:1883)
```

> The MQTT warning `"could not connect to broker"` is **normal** if you don't have Mosquitto running. The server starts and works fully — MQTT is just disabled until you start a broker.

**Interactive API docs:** Open http://localhost:8000/docs — every endpoint is documented and testable there.

---

## 4. All API Endpoints

### Auth

#### `POST /auth/register` — Register any actor
```bash
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Ramesh Beekeeper",
    "role": "beekeeper",
    "password": "secure123",
    "region": "Wardha, Maharashtra",
    "wallet_address": "0xYourWalletAddress",
    "village": "Wardha",
    "district": "Wardha",
    "state": "Maharashtra"
  }'
```

Returns: `{ "id": "uuid", "role": "beekeeper", "name": "...", ... }`

Valid roles: `admin`, `beekeeper`, `processor`, `lab`, `distributor`, `retailer`

---

#### `POST /auth/login` — Get a JWT token
```bash
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"name": "Ramesh Beekeeper", "password": "secure123"}'
```

Returns: `{ "access_token": "eyJ...", "token_type": "bearer", "actor_id": "uuid", "role": "beekeeper" }`

**Save the `access_token` — use it as `Authorization: Bearer <token>` for all protected endpoints.**

---

### Hives

#### `POST /hive/` — Register a hive
```bash
curl -X POST http://localhost:8000/hive/ \
  -H "Authorization: Bearer <YOUR_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "beekeeper_id": "<BEEKEEPER_ACTOR_UUID>",
    "device_id": "ESP32-001",
    "region_public": "Wardha, Maharashtra",
    "gps_lat": 20.745,
    "gps_lon": 78.602
  }'
```

Returns: `{ "id": "hive-uuid", "device_id": "ESP32-001", ... }`

---

#### `POST /hive/sensor-data` — Manually push sensor reading
```bash
curl -X POST http://localhost:8000/hive/sensor-data \
  -H "Authorization: Bearer <YOUR_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "hive_id": "<HIVE_UUID>",
    "ts": "2026-09-11T10:30:00",
    "temperature_c": 34.2,
    "humidity_pct": 61.8,
    "pressure_hpa": 1009.4,
    "weight_kg": 27.35,
    "battery_pct": 84,
    "source": "api",
    "is_simulated": true
  }'
```

> For the demo, set `"is_simulated": true`. The ESP32 MQTT path sets this to `false` automatically.

---

#### `GET /hive/{hive_id}/sensor-data?limit=20` — Latest sensor readings
```bash
curl -H "Authorization: Bearer <YOUR_TOKEN>" \
  "http://localhost:8000/hive/<HIVE_UUID>/sensor-data?limit=20"
```

Returns an array of the 20 most recent readings (newest first).

---

### Harvests & Batches

#### `POST /harvest` — Record a harvest
```bash
curl -X POST http://localhost:8000/harvest \
  -H "Authorization: Bearer <YOUR_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "hive_id": "<HIVE_UUID>",
    "harvest_date": "2026-09-10T08:00:00",
    "quantity_g": 25000,
    "floral_source": "Multiflora",
    "notes": "First harvest of the season"
  }'
```

Returns: `{ "id": "harvest-uuid", "quantity_g": 25000, ... }`

---

#### `POST /batch` — **The main operation: create a blockchain batch**

This single call: uploads metadata to IPFS → submits a blockchain transaction → persists to DB → generates a QR token.

```bash
curl -X POST http://localhost:8000/batch \
  -H "Authorization: Bearer <YOUR_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "batch_code": "HC-2026-WD-000001",
    "harvest_id": "<HARVEST_UUID>",
    "honey_type": "Multiflora",
    "region": "Wardha, Maharashtra"
  }'
```

Returns:
```json
{
  "id": "batch-uuid",
  "batch_code": "HC-2026-WD-000001",
  "batch_hash": "0xabc...def",
  "status": "Created",
  "metadata_cid": "QmXxx...",
  "metadata_hash": "sha256hex...",
  "contract_address": "0x5BFA55A855Da3687d0f9CDA33ae3f64f7a3629aB",
  "create_tx_hash": "0xtxhash...",
  "created_at": "2026-09-11T...",
  "qr_url": "http://localhost:8000/verify/HC-2026-WD-000001?n=abc&sig=def"
}
```

**Give the `qr_url` to Flutter — encode it into a QR code and show it to the judge.**

---

#### `GET /batch/code/{batch_code}` — Look up a batch by code
```bash
curl -H "Authorization: Bearer <YOUR_TOKEN>" \
  "http://localhost:8000/batch/code/HC-2026-WD-000001"
```

---

#### `POST /lab-verification` — Record lab certificate hash on-chain

Register as a `lab` actor first, then:

```bash
curl -X POST http://localhost:8000/lab-verification \
  -H "Authorization: Bearer <LAB_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "batch_id": "<BATCH_UUID>",
    "certificate_hash": "0xabcdef1234567890...",
    "certificate_cid": "QmLabCertCID"
  }'
```

> The `certificate_hash` should be `"0x" + sha256(lab_certificate.pdf).hexdigest()`.

---

#### `POST /batch/{batch_id}/transfer` — Transfer custody
```bash
curl -X POST "http://localhost:8000/batch/<BATCH_UUID>/transfer" \
  -H "Authorization: Bearer <CUSTODIAN_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "to_actor_id": "<DISTRIBUTOR_ACTOR_UUID>",
    "next_status": "InDistribution"
  }'
```

Valid status values: `Created`, `Harvested`, `Processed`, `LabVerified`, `Packaged`, `InDistribution`, `AtRetail`, `Sold`

---

#### `POST /batch/{batch_id}/recall` — Admin recall
```bash
curl -X POST "http://localhost:8000/batch/<BATCH_UUID>/recall" \
  -H "Authorization: Bearer <ADMIN_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"reason": "Contamination detected in lab test"}'
```

---

### Consumer Verification (Public — no auth needed)

#### `GET /verify/{batch_code}?n=&sig=` — QR scan verification
```bash
# The full URL comes from the qr_url field in the batch creation response
curl "http://localhost:8000/verify/HC-2026-WD-000001?n=<NONCE>&sig=<SIGNATURE>"
```

Returns:
```json
{
  "batch_code": "HC-2026-WD-000001",
  "status": "Created",
  "beekeeper_name": "Ramesh Beekeeper",
  "region": "Wardha, Maharashtra",
  "harvest_date": "2026-09-10T08:00:00",
  "quantity_g": 25000,
  "blockchain": {
    "contract_address": "0x5BFA55...",
    "transaction_hash": "0xtxhash...",
    "block_explorer_url": "https://amoy.polygonscan.com/tx/0xtxhash...",
    "batch_hash_on_chain": "0xbatchhash...",
    "metadata_cid": "QmXxx...",
    "metadata_hash_on_chain": "sha256hex...",
    "lab_verified": false,
    "recalled": false
  },
  "ipfs": {
    "cid": "QmXxx...",
    "gateway_url": "https://gateway.pinata.cloud/ipfs/QmXxx...",
    "hash_matches": true
  },
  "scan_count": 1,
  "duplicate_warning": false
}
```

**Demo invalid QR:** Change one character in the `sig` param → `400 Invalid QR signature`.
**Demo recalled batch:** After calling `/recall`, verification returns `"status": "RECALLED"`.

---

### AI Disease Detection

#### `POST /disease-detection/` — Upload a bee image
```bash
curl -X POST http://localhost:8000/disease-detection/ \
  -H "Authorization: Bearer <YOUR_TOKEN>" \
  -F "image=@/path/to/bee_photo.jpg" \
  -F "hive_id=<HIVE_UUID>"
```

Returns:
```json
{
  "prediction": "uncertain",
  "confidence": 0.50,
  "model_version": "bee-health-efficientnet-b0-stub-v0.1",
  "inference_timestamp": "2026-09-11T...",
  "input_image_hash": "sha256_of_uploaded_image",
  "inference_id": "uuid",
  "warning": "Confidence below 0.70 — manual inspection required"
}
```

> **Note:** The `prediction` is `uncertain` until the AI team integrates the real model. The `input_image_hash` changes with every different image — this is the audit trail value for judges.

---

## 5. End-to-End Demo Walkthrough

Run these commands **in order** to reproduce the full judge demo:

```bash
BASE="http://localhost:8000"

# 1. Register a beekeeper
BEEKEEPER=$(curl -s -X POST $BASE/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Demo Beekeeper","role":"beekeeper","password":"demo123","region":"Wardha"}')
BEEKEEPER_ID=$(echo $BEEKEEPER | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")
echo "Beekeeper ID: $BEEKEEPER_ID"

# 2. Login → get token
TOKEN=$(curl -s -X POST $BASE/auth/login \
  -H "Content-Type: application/json" \
  -d '{"name":"Demo Beekeeper","password":"demo123"}' \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")
echo "Token: ${TOKEN:0:20}..."

# 3. Register a hive
HIVE=$(curl -s -X POST $BASE/hive/ \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"beekeeper_id\":\"$BEEKEEPER_ID\",\"device_id\":\"ESP32-001\",\"region_public\":\"Wardha\"}")
HIVE_ID=$(echo $HIVE | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")
echo "Hive ID: $HIVE_ID"

# 4. Push a simulated sensor reading
curl -s -X POST $BASE/hive/sensor-data \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"hive_id\":\"$HIVE_ID\",\"ts\":\"2026-09-11T10:00:00\",\"temperature_c\":34.2,\"humidity_pct\":61.8,\"weight_kg\":27.35,\"is_simulated\":true}"
echo "Sensor reading pushed."

# 5. Record a harvest
HARVEST=$(curl -s -X POST $BASE/harvest \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"hive_id\":\"$HIVE_ID\",\"harvest_date\":\"2026-09-10T08:00:00\",\"quantity_g\":25000,\"floral_source\":\"Multiflora\"}")
HARVEST_ID=$(echo $HARVEST | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")
echo "Harvest ID: $HARVEST_ID"

# 6. Create the blockchain batch (IPFS + Polygon + QR)
echo "Creating blockchain batch (takes ~5s for Polygon confirmation)..."
BATCH=$(curl -s -X POST $BASE/batch \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"batch_code\":\"HC-DEMO-001\",\"harvest_id\":\"$HARVEST_ID\",\"honey_type\":\"Multiflora\",\"region\":\"Wardha\"}")
echo $BATCH | python3 -m json.tool

# 7. Extract tx hash and QR URL
TX=$(echo $BATCH | python3 -c "import sys,json; print(json.load(sys.stdin)['create_tx_hash'])")
QR_URL=$(echo $BATCH | python3 -c "import sys,json; print(json.load(sys.stdin)['qr_url'])")
echo ""
echo "View on Polygonscan: https://amoy.polygonscan.com/tx/$TX"
echo ""
echo "QR URL: $QR_URL"
echo ""

# 8. Verify the QR (simulates a consumer scan)
echo "Consumer verification response:"
curl -s "$QR_URL" | python3 -m json.tool

# 9. Demo invalid QR — tamper the signature
INVALID_URL=$(echo $QR_URL | sed 's/sig=.*/sig=TAMPERED/')
echo ""
echo "Tampered QR response (should be 400):"
curl -s "$INVALID_URL"
```

---

## 6. QR Verification Flow Explained

### What's in the QR code

```
http://localhost:8000/verify/HC-DEMO-001?n=abc123xyz&sig=hmac_sha256_hex
```

- `HC-DEMO-001` — the batch code (human-readable)
- `n=abc123xyz` — a random nonce (generated fresh for each batch)
- `sig=...` — `HMAC-SHA256(QR_HMAC_SECRET, "HC-DEMO-001:abc123xyz")`

### Why this is secure

A QR code is just a URL — anyone can copy it. The HMAC signature means:
1. You can't forge a valid URL without knowing `QR_HMAC_SECRET`
2. A URL for batch `HC-DEMO-001` doesn't work for `HC-DEMO-002` (different signature)
3. Changing any character in the URL → signature mismatch → `400` error

### What the `/verify` endpoint does step by step

```
Consumer scans QR
    ↓
Validate HMAC-SHA256 signature (fails immediately if forged — no DB hit)
    ↓
Query PostgreSQL → get batch record
    ↓
Query Polygon RPC → getBatch() on smart contract (live blockchain read, free)
    ↓
Fetch IPFS CID from gateway → recompute SHA-256 → compare with on-chain hash
    ↓
Log scan (increment scan_count, record IP region, timestamp)
    ↓
If scan_count ≥ 5 → set duplicate_warning: true (possible QR cloning alert)
    ↓
Return combined proof JSON to consumer
```

### Hash integrity check — `hash_matches: true`

The IPFS metadata is fetched live and its SHA-256 is recomputed. This is compared against the `metadataHash` stored permanently on the Polygon smart contract. If someone altered the IPFS file after pinning, the hash would differ → `hash_matches: false` → tamper proven.

---

## 7. Running the Tests

```bash
cd polygon/backend
source venv/bin/activate
pip install pytest httpx   # httpx needed by FastAPI TestClient
pytest tests/ -v
```

Expected output (20 tests, all passing):
```
tests/test_backend.py::test_qr_token_round_trip                     PASSED
tests/test_backend.py::test_qr_token_wrong_batch_code_fails         PASSED
tests/test_backend.py::test_qr_token_tampered_signature_fails       PASSED
tests/test_backend.py::test_qr_token_wrong_nonce_fails              PASSED
tests/test_backend.py::test_qr_url_contains_batch_code              PASSED
tests/test_backend.py::test_canonical_json_is_deterministic         PASSED
tests/test_backend.py::test_sha256_hex_known_value                  PASSED
tests/test_backend.py::test_password_round_trip                     PASSED
tests/test_backend.py::test_jwt_token_contains_role                 PASSED
tests/test_backend.py::test_batch_id_hash_is_32_bytes               PASSED
tests/test_backend.py::test_metadata_bytes32_is_32_bytes            PASSED
tests/test_backend.py::test_batch_id_hash_is_deterministic          PASSED
tests/test_backend.py::test_different_batch_codes_produce_diff_hashes PASSED
tests/test_backend.py::test_health_check                            PASSED
tests/test_backend.py::test_openapi_docs_available                  PASSED
tests/test_backend.py::test_register_creates_actor                  PASSED
tests/test_backend.py::test_login_wrong_credentials_returns_401     PASSED
tests/test_backend.py::test_verify_invalid_signature_returns_400    PASSED
tests/test_backend.py::test_legacy_create_batch_requires_body       PASSED
tests/test_backend.py::test_protected_endpoint_requires_auth        PASSED
```

> Tests run without a real database, blockchain, or IPFS — they mock all external dependencies.

---

## 8. AI Team — How to Plug In the Real Model

Only **one function** needs to change. Open [`app/api/ai.py`](app/api/ai.py) and find `_run_inference`:

```python
def _run_inference(_image_bytes: bytes) -> tuple[str, float]:
    """
    === AI TEAM: replace this stub with real model inference ===
    """
    return "uncertain", 0.50   # ← replace these two lines
```

Replace with your EfficientNet-B0 call:

```python
# Load model once at module level (not inside the function, for speed)
import torch
from torchvision import transforms
from PIL import Image
import io

_model = torch.load("path/to/model.pt", map_location="cpu")
_model.eval()
_CLASSES = ["healthy", "varroa_suspected", "pollen_carrier", "uncertain"]
_transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225]),
])

def _run_inference(image_bytes: bytes) -> tuple[str, float]:
    img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    tensor = _transform(img).unsqueeze(0)
    with torch.no_grad():
        probs = torch.softmax(_model(tensor), dim=1)
        confidence, idx = probs.max(dim=1)
    return _CLASSES[idx.item()], confidence.item()
```

Also update the version string near the top of the file:
```python
_MODEL_VERSION = "bee-health-efficientnet-b0-v1.0"   # was: "stub-v0.1"
```

**Everything else is already done:** image hashing, confidence threshold check, DB persistence, response schema, error handling.

---

## 9. IoT / MQTT Explained

The MQTT subscriber starts automatically when `uvicorn` starts. It runs as a silent background thread.

### What it listens to
Topic: `honeychain/hives/+/telemetry`

### Expected message format (from ESP32 or simulator)
```json
{
  "hiveId": "your-hive-uuid-here",
  "deviceId": "ESP32-001",
  "temperatureC": 34.2,
  "humidityPct": 61.8,
  "pressureHPa": 1009.4,
  "weightKg": 27.35,
  "batteryPct": 84,
  "timestamp": "2026-09-11T10:30:00+05:30",
  "isSimulated": false
}
```

### To test MQTT without hardware

```bash
# Install Mosquitto (macOS)
brew install mosquitto
brew services start mosquitto

# Publish a test reading (replace the UUID with a real hive ID from your DB)
mosquitto_pub \
  -t "honeychain/hives/YOUR-HIVE-UUID/telemetry" \
  -m '{"hiveId":"YOUR-HIVE-UUID","temperatureC":34.2,"humidityPct":61.8,"weightKg":27.35,"batteryPct":84,"timestamp":"2026-09-11T10:30:00","isSimulated":true}'
```

The reading will appear in the database immediately and in `GET /hive/{id}/sensor-data`.

### Without Mosquitto

If Mosquitto isn't running, the server prints a warning and continues normally. Use `POST /hive/sensor-data` to push readings manually for the demo.

---

## 10. Troubleshooting

| Problem | Cause | Fix |
|---|---|---|
| `ModuleNotFoundError: No module named 'fastapi'` | Wrong venv or pip not done | `source venv/bin/activate && pip install -r requirements.txt` |
| `venv/bin/pip: bad interpreter` | Old broken venv | `rm -rf venv && python3 -m venv venv` |
| `could not translate host name "localhost"` | PostgreSQL not running | `brew services start postgresql@16` |
| `FATAL: role "honeychain" does not exist` | DB user not created | Run `CREATE USER honeychain WITH PASSWORD 'honeychain';` in psql |
| `CommandError: Can't locate revision` | Wrong directory for alembic | Must run from `polygon/backend/` |
| `RuntimeError: Smart contract ABI not loaded` | Contract not compiled | `cd polygon/blockchain && npx hardhat compile` |
| `502: IPFS upload failed` | Pinata JWT expired | Get new JWT from pinata.cloud dashboard |
| `502: Blockchain tx failed` | Out of test MATIC | Get tokens from https://faucet.polygon.technology/ |
| `MQTT: could not connect to broker` | Mosquitto not running | Normal — server works without it. Start Mosquitto to enable IoT |
| `401 Unauthorized` | Missing auth header | Add `Authorization: Bearer <token>` |
| `403 Forbidden` | Wrong role for endpoint | Register an actor with the correct role |
| `422 Unprocessable Entity` | Request body missing required field | Check the `/docs` page for the required schema |

---

## 11. Flutter Team — API Contract

| Screen | Endpoint | Method | Auth? |
|---|---|---|---|
| Login | `/auth/login` | POST | No |
| Register | `/auth/register` | POST | No |
| Register hive | `/hive/` | POST | Yes (Beekeeper) |
| Sensor dashboard | `/hive/{id}/sensor-data?limit=50` | GET | Yes |
| AI bee image upload | `/disease-detection/` | POST (multipart) | Yes |
| Create harvest | `/harvest` | POST | Yes (Beekeeper) |
| Create batch + QR | `/batch` | POST | Yes (Beekeeper) |
| Show QR code | Use `qr_url` from batch response | — | — |
| Consumer verification page | `/verify/{batchCode}?n=&sig=` | GET | **No** (public) |
| Lab verification | `/lab-verification` | POST | Yes (Lab) |
| Custody transfer | `/batch/{id}/transfer` | POST | Yes (custodian) |
| Polygonscan link | `block_explorer_url` from verify response | — | — |
| IPFS metadata link | `gateway_url` from verify response | — | — |

### Base URL
- Local dev: `http://localhost:8000`
- Production: update `BACKEND_BASE_URL` in `.env` and in Flutter

### Auth header
```
Authorization: Bearer eyJhbGci...
```

### Legacy endpoint (existing Flutter demo code still works)
`POST /create-batch` — preserved unchanged with the same request/response shape.
