# Honey Chain Technical Research and Implementation Report

Date: 2026-09-05

## 1. Executive Summary

Build Honey Chain as a judge-verifiable prototype using:

- Frontend: Flutter web/mobile
- Backend: Python FastAPI
- Database: PostgreSQL
- IoT: ESP32 + BME280 + load cell + HX711, publishing MQTT
- AI: EfficientNet-B0/MobileNetV3 for bee image classification, XGBoost for yield-risk prediction
- Blockchain: Polygon Amoy testnet, Solidity, OpenZeppelin, Hardhat Ignition, MetaMask
- Storage: IPFS through Pinata
- QR: signed dynamic verification URL that resolves to backend + blockchain + IPFS evidence

The decisive recommendation is: **Polygon Amoy + Solidity + OpenZeppelin + Hardhat + MetaMask + Pinata/IPFS + FastAPI + PostgreSQL + Flutter + ESP32/MQTT**.

Reason: it is low-cost, EVM-compatible, fast enough for demo use, has public explorers, works with MetaMask, supports Solidity contracts, and lets judges independently inspect transactions/events. Hyperledger Fabric is strong for enterprise consortium deployments, but it is too heavy for a fast SIH prototype and weaker for public judge verification unless a full permissioned network is deployed.

Do not claim blockchain proves the honey itself is genuine. Blockchain proves that recorded evidence, certificates, custody events, and hashes were not silently altered after recording. Physical authenticity still requires lab tests, chain of custody, and trusted actor onboarding.

## 2. Bitcoin and Blockchain Basics for Honey Chain

Bitcoin is a public blockchain-based currency network. It lets users transfer bitcoin without a central bank by maintaining a distributed ledger replicated by many nodes.

Honey Chain is not storing money transfers. It stores **evidence about honey batches**: who created a batch, when harvest/processing/testing/packaging happened, who owned custody, what IPFS metadata CID was attached, and which certificate hash was committed.

Key Bitcoin concepts in Honey Chain context:

| Concept | Bitcoin meaning | Honey Chain meaning |
|---|---|---|
| Block | Group of Bitcoin transactions added to chain | Group of Polygon transactions, including HoneyBatch events |
| Transaction | Transfer of BTC or contract interaction | Create batch, verify lab test, transfer custody, revoke batch |
| Wallet | Key-managed account holding BTC | Beekeeper/lab/admin/distributor blockchain account |
| Public key/address | Public receiving identity | Actor address visible on explorer |
| Private key | Secret authorizes spending | Secret authorizes Honey Chain writes; must never be in Git |
| Digital signature | Proves transaction was signed by wallet | Proves event was submitted by authorized actor |
| Hashing | Fingerprint of transaction/block data | Fingerprint of certificate/metadata/QR payload |
| Proof of Work | Bitcoin mining security mechanism | Not used directly; Polygon Amoy uses Polygon's PoS-style EVM testnet environment |
| Consensus | Network agrees on valid ledger state | Public nodes agree that a batch transaction/event exists |
| Distributed ledger | Many nodes keep a common ledger | Judges can inspect a public copy via Polygon explorer |

Bitcoin is not ideal for Honey Chain because Bitcoin Script is intentionally limited for general smart contracts, transactions are relatively slow and expensive for frequent supply-chain events, and it is not designed for structured application state. Honey Chain needs programmable smart contracts and cheap public transactions, so an EVM smart-contract chain is a better fit.

## 3. Why Bitcoin Is/Isn't Appropriate

Bitcoin is useful as the mental model: an append-only ledger, transaction hashes, digital signatures, and public verification. It is not the implementation target.

What goes on-chain in Honey Chain:

- Batch ID hash
- Beekeeper/lab/custodian wallet addresses
- IPFS CID or CID hash
- Certificate hash
- Stage/status
- Timestamps via block time and event fields
- Transfer and revocation events

What does not go on-chain:

- Raw sensor streams
- GPS coordinates at full precision
- Personal IDs/documents
- Full lab reports
- Images
- AI model files
- Large metadata JSON

## 4. Blockchain Selection

| Network | Public/permissioned | Cost | Speed | Smart contracts | Testnet | Wallet/explorer | QR suitability | Hackathon suitability | Long-term scalability |
|---|---|---|---|---|---|---|---|---|---|
| Ethereum mainnet | Public | High | Moderate | Solidity/EVM | Sepolia | Excellent | Excellent but expensive | Weak for low-budget demo | Strong security, costly |
| Ethereum Sepolia | Public testnet | Free test ETH | Moderate | Solidity/EVM | Yes | MetaMask + Etherscan | Excellent | Good, but slower/costlier mainnet path | Good for Ethereum learning |
| Polygon PoS mainnet | Public | Low | Fast | Solidity/EVM | Amoy | MetaMask + Polygonscan | Excellent | Strong | Strong for many low-value traceability events |
| Polygon Amoy | Public testnet | Free test MATIC | Fast | Solidity/EVM | Yes | MetaMask + Amoy Polygonscan | Excellent | Best | Testnet only; deploy mainnet later |
| Avalanche C-Chain | Public | Low/moderate | Fast | Solidity/EVM | Fuji | MetaMask + Snowtrace/Subnetscan | Good | Good | Strong, but less familiar to many judges |
| BNB Smart Chain | Public | Low | Fast | Solidity/EVM | BSC Testnet | MetaMask + BscScan | Good | Good | Strong, more centralized validator concerns |
| Hyperledger Fabric | Permissioned | Infra cost | Fast | Chaincode | Local/test networks | No public wallet by default | Good for enterprise QR, weak public proof | Too heavy | Excellent for KVIC consortium if institutions run nodes |
| Base/Sepolia or Arbitrum Sepolia | Public L2 | Low | Fast | Solidity/EVM | Yes | MetaMask + explorers | Good | Good | Strong, but Polygon has clearer India hackathon fit |

Recommendation: **Polygon Amoy testnet for SIH prototype.** It gives public, fast, low-cost EVM transactions and explorer-verifiable evidence. For production under KVIC, evaluate Polygon PoS mainnet for public consumer proof, or Hyperledger Fabric if KVIC requires a closed institutional network with role-based participants.

Official docs:

- Polygon documentation: https://docs.polygon.technology/
- Polygon Amoy testnet: https://docs.polygon.technology/pos/get-started/building-on-polygon/
- Amoy explorer: https://amoy.polygonscan.com/
- Polygon faucet: https://faucet.polygon.technology/
- Ethereum Sepolia docs: https://ethereum.org/en/developers/docs/networks/
- Ethereum testnets: https://ethereum.org/en/developers/docs/networks/#sepolia
- Avalanche docs: https://docs.avax.network/
- BNB Chain docs: https://docs.bnbchain.org/
- Hyperledger Fabric docs: https://hyperledger-fabric.readthedocs.io/

## 5. Problem Research

KVIC Honey Mission distributes bee boxes, bee colonies, and toolkits to rural beneficiaries to increase livelihood opportunities through beekeeping. Source: KVIC official site, https://www.kvic.gov.in/.

India also has the National Beekeeping and Honey Mission and National Bee Board initiatives. The Madhukranti portal was launched for honey traceability/online registration and is relevant prior art for any Honey Chain proposal. Sources:

- National Bee Board: https://nbb.gov.in/
- Madhukranti portal: https://madhukrantiportal.in/
- Ministry/NBHM references: https://agricoop.nic.in/

Core problems:

- Counterfeit/adulterated honey lowers consumer trust.
- Small beekeepers lack direct market access and proof of origin.
- Lab certificates and custody records can be disconnected from the product.
- Hive health issues such as Varroa infestation and disease reduce productivity.
- IoT adoption is limited by cost, power, network coverage, and maintenance.

Honey adulteration is a documented concern in India. FSSAI regulates honey standards and methods, while independent reports such as CSE's 2020 investigation raised concerns about adulteration detection by advanced testing. Use this carefully: cite it as evidence of consumer-trust risk, not as proof against every brand.

Sources:

- FSSAI: https://www.fssai.gov.in/
- FSSAI standards and methods portal: https://fssai.gov.in/cms/food-safety-and-standards-regulations.php
- CSE honey report: https://www.cseindia.org/

## 6. Dataset Research

### A. Bee Disease Detection

| Dataset | URL | Source | Size/classes | Format/labels | License/use | Suitability |
|---|---|---|---|---|---|---|
| TensorFlow `bee_dataset` / BeeAlarmed | https://www.tensorflow.org/datasets/catalog/bee_dataset and https://github.com/BeeAlarmed/BeeDataset | TensorFlow Datasets / BeeAlarmed | 7,490 train examples; labels: `cooling_output`, `pollen_output`, `varroa_output`, `wasps_output` | RGB images, 300x150/200x100/150x75 configs; multilabel outputs | GPL-3.0 from source repo; commercial use possible only under GPL obligations | **Best reproducible MVP dataset** for varroa/pollen/wasp/cooling screening |
| Honey Bee Annotated Images / BeeImage | https://www.kaggle.com/datasets/jenny18/honey-bee-annotated-images | Kaggle/Jenny Yang | 5,100+ or 5,172 bee images; labels include location, date/time, subspecies, health, caste, pollen | PNG/JPG bee crops + CSV labels | Reported as CC0/Public Domain by third-party dataset index; verify Kaggle page at download time | Best simple classifier dataset; useful for healthy/varroa-like health labels |
| Bee Dataset BUT-1 | https://www.kaggle.com/datasets/simonbilk/bee-dataset-but-1 | Kaggle / Brno University of Technology | 1,153 manually annotated images; classes include bee body/cluster parts | Images + annotations | LGPL-3.0 | Good for bee localization/inspection preprocessing, not disease coverage |
| Bee or Wasp? | https://www.kaggle.com/datasets/jerzydziewierz/bee-vs-wasp | Kaggle | Bee/wasp/insect classes | Images + labels | Verify Kaggle license | Good auxiliary negative-class dataset, not disease detection |
| VarroaDataset | https://zenodo.org/records/4085044 | Zenodo | Lab-controlled Varroa imagery; used by later YOLO studies; one public summary reports 3,946 infected images at 160x280 | Images/annotations depending release | License must be checked on Zenodo record; do not assume commercial permission | Useful for object detection if labels are available |
| Roboflow Universe Bee Health Data 2.0 | https://universe.roboflow.com/bees-31jk6/bee-health-data-2.0-jgnjn-n6xrc | Roboflow | Aggregated bee health detection data; classes exposed in API include healthy, infected, pollen carrier | YOLO/COCO-style exports where allowed | Per-dataset license and Roboflow terms must be checked | Fastest YOLO demo path, but quality/licensing varies |
| FAIRHiveFrames-1K | https://pmc.ncbi.nlm.nih.gov/articles/PMC13120227/ | Public FAIR dataset paper | 1,265 hive-frame images; 7 categories including capped honey cell, brood, empty comb, pollen, nectar, larva, frame | Bounding boxes; YOLOv8/YOLO11 baselines | Open paper; dataset license must be checked from repository | Useful for hive-frame condition/yield support, not disease diagnosis |
| BeeAlarmed / open bee monitoring repos | https://github.com/search?q=bee+disease+detection+dataset | GitHub | Varies | Varies | Repository license varies | Use only after license verification |

Practical conclusion: no single clean public image dataset covers Varroa, Nosema, deformed wing virus, American foulbrood, European foulbrood, chalkbrood, and healthy bees with enough balanced images for a reliable production classifier. For the prototype:

- Train disease/health classifier on Honey Bee Annotated Images.
- Add Varroa object-detection if VarroaDataset/Roboflow labels are usable.
- Label the model as **screening support**, not diagnosis.
- Keep "lab verification required" for final authenticity.

Recommended model:

- MVP: EfficientNet-B0 or MobileNetV3-small classifier for mobile-friendly bee health classes.
- Optional detection: YOLOv8n/YOLO11n for Varroa mite bounding boxes if labels exist.
- Training: 10-30 epochs on Colab T4/L4, 224x224 images, augmentation, class-weighting.
- Metrics: accuracy, macro F1, precision/recall per class, confusion matrix.

### B. Hive Environmental Data

Use a hybrid approach:

1. Real hardware for live temperature, humidity, and hive weight.
2. Public weather API for rainfall/wind/pressure/location weather context.
3. Simulated stream only when hardware is absent, visibly labeled "Simulated demo stream".
4. Historical public datasets for offline model experiments.

Useful sources/APIs:

- OpenWeather API docs: https://openweathermap.org/api
- Open-Meteo API docs: https://open-meteo.com/en/docs
- Visual Crossing weather docs: https://www.visualcrossing.com/resources/documentation/weather-api/
- NASA POWER climate API: https://power.larc.nasa.gov/docs/services/api/

### C. Honey Production / Yield Prediction

A generally reusable public dataset with hive weight + colony strength + microclimate + flowering/forage + harvest dates + actual honey yield is not reliably available in a standard benchmark form. Some research groups and smart hive projects publish partial hive weight/temperature datasets, but they often lack verified harvest labels or are location-specific.

Prototype dataset strategy:

- Use real ESP32 sensor readings during the demo.
- Store daily aggregate hive weight delta, temperature, humidity, rainfall, season, region, floral-source proxy, and manually entered harvest quantity.
- For hackathon prediction, train XGBoost on a clearly labeled **prototype training table** created from public weather history plus manually entered or literature-inspired sample values.
- UI must say: "Yield model trained on prototype dataset; production deployment requires local cluster harvest history."

Do not fabricate "real honey yield" data.

## 7. Existing Solutions

| Solution | Blockchain | IoT | AI | QR | Traceability | Gap Honey Chain addresses |
|---|---:|---:|---:|---:|---:|---|
| Madhukranti portal | Government traceability portal; blockchain not central | No | No | Registration/traceability oriented | Yes | Honey Chain adds public blockchain evidence, AI/IoT hive health, live judge proof |
| IBM Food Trust | Yes | Integrates data sources | Not core | Supports consumer transparency | Yes | Enterprise platform, not honey-specific rural beekeeper MVP |
| TE-Food | Yes | Integrates supply-chain events | Not disease-focused | Yes | Yes | Food traceability, not smart apiculture |
| OpenSC | Blockchain/digital traceability | Integrations | Analytics | Consumer proof | Yes | Enterprise sustainability traceability, not KVIC smart hive toolkit |
| BroodMinder | No blockchain | Yes | Analytics | No | Hive monitoring | Does not prove batch provenance |
| Arnia | No blockchain | Yes | Analytics | No | Hive monitoring | No public batch authenticity proof |
| BeeHero | No public batch blockchain | Yes | AI/pollination analytics | No | Colony/pollination | Not consumer honey QR authenticity |
| Beewise | No public batch blockchain | Robotic hive | AI | No | Hive management | High-cost hardware, not low-cost rural deployment |

Strongest differentiator: **one integrated proof chain from low-cost hive data and AI screening to batch custody, lab certificate hash, IPFS metadata, blockchain event, and QR consumer verification.**

## 8. Proposed Architecture

```text
Beekeeper Flutter App
        |
        v
ESP32 Sensors -> MQTT Broker -> FastAPI Backend
        |                         |
        |                         v
        |                  PostgreSQL Database
        |                         |
        v                         v
AI Services <--------------- Batch Workflow
        |                         |
        v                         v
IPFS/Pinata Metadata ----> Solidity Smart Contract on Polygon Amoy
                                  |
                                  v
                             QR Code URL
                                  |
                                  v
                   Consumer Verification Web Page
                                  |
                                  v
              Polygon Explorer + IPFS Gateway evidence
```

Components:

- Beekeeper app: actor onboarding, hive registration, sensor dashboard, harvest creation, QR printing.
- IoT sensors: weight, temperature, humidity, optional GPS.
- MQTT broker: lightweight sensor ingestion.
- FastAPI: validates users, signs QR payloads, stores off-chain data, submits contract calls.
- AI service: image disease screening and yield-risk prediction.
- PostgreSQL: operational database and query layer.
- IPFS/Pinata: immutable metadata/certificate storage by content CID.
- Smart contract: minimal public evidence registry.
- QR verification page: resolves signed batch ID, fetches backend summary, verifies blockchain and IPFS evidence.

## 9. Blockchain Data Model

| Data | Blockchain? | Off-chain? | Why? |
|---|---:|---:|---|
| Beekeeper ID | Hash/address only | Yes | Avoid PII on-chain |
| Hive ID | Hash only | Yes | Linkable but privacy-preserving |
| Hive location | Region only | Exact GPS | Prevent theft/privacy risk |
| GPS coordinates | No | Yes, protected | Sensitive and mutable |
| Sensor readings | Hash of aggregate optional | Yes | Raw streams are too large |
| Temperature | No | Yes | High-volume telemetry |
| Humidity | No | Yes | High-volume telemetry |
| Hive weight | Daily aggregate hash optional | Yes | Cost/scalability |
| Disease prediction | Hash/result summary optional | Yes | Model outputs may be wrong; keep audit trail |
| AI model result | CID/hash | Yes | Versioned off-chain artifact |
| Harvest date | Yes | Yes | Core provenance |
| Harvest quantity | Yes, coarse | Yes, exact | Core batch attribute; exact values may be business-sensitive |
| Batch ID | Hash/string | Yes | Main lookup key |
| Processing information | Status hash/CID | Yes | Detailed records off-chain |
| Lab test result | Certificate hash + verifier | Full report | Authenticity evidence without exposing full document |
| Certificate hash | Yes | Yes | Tamper-evident |
| Packaging event | Yes | Yes | Chain-of-custody milestone |
| Distributor transfer | Yes | Yes | Ownership/custody evidence |
| Retailer transfer | Yes | Yes | Ownership/custody evidence |
| QR code | Signed payload hash | Rendered image | QR can be cloned; signature and lookup matter |
| IPFS CID | Yes | Yes | Points to immutable metadata |
| Timestamp | Yes | Yes | Block time plus backend time |
| Digital signature | Wallet tx signature | API/QR signatures | Proves authorized writes |

Privacy/cost/scalability rule: only store small, stable, public-verification facts on-chain. Everything large, private, noisy, or frequently changing stays off-chain with hashes/CIDs committed.

## 10. Smart Contract Design

Use OpenZeppelin AccessControl and Pausable. Do not make the consumer scan create a transaction; reads should be free.

Core states:

```solidity
enum BatchStatus {
    Created,
    Harvested,
    Processed,
    LabVerified,
    Packaged,
    InDistribution,
    AtRetail,
    Sold,
    Recalled,
    Rejected
}

struct HoneyBatch {
    bytes32 batchIdHash;
    address beekeeper;
    address currentCustodian;
    uint64 harvestTimestamp;
    uint64 createdAt;
    uint32 quantityGrams;
    BatchStatus status;
    string metadataCID;
    bytes32 metadataHash;
    bytes32 labReportHash;
    bool labVerified;
    bool recalled;
}
```

Roles:

- DEFAULT_ADMIN_ROLE: project/KVIC admin
- BEEKEEPER_ROLE: create harvest/batch
- PROCESSOR_ROLE: register processing/packaging
- LAB_ROLE: verify lab certificate hash
- DISTRIBUTOR_ROLE: accept transfer
- RETAILER_ROLE: retail receipt/sale

Functions:

- `createBatch(bytes32 batchIdHash, uint32 quantityGrams, uint64 harvestTimestamp, string metadataCID, bytes32 metadataHash)`
- `registerProcessing(bytes32 batchIdHash, string metadataCID, bytes32 metadataHash)`
- `verifyLab(bytes32 batchIdHash, bytes32 labReportHash, string metadataCID, bytes32 metadataHash)`
- `packageBatch(bytes32 batchIdHash, string metadataCID, bytes32 metadataHash)`
- `transferCustody(bytes32 batchIdHash, address to, uint8 nextStatus)`
- `markRetail(bytes32 batchIdHash, address retailer)`
- `markSold(bytes32 batchIdHash)`
- `recallBatch(bytes32 batchIdHash, string reasonCID)`
- `rejectBatch(bytes32 batchIdHash, string reasonCID)`
- `getBatch(bytes32 batchIdHash) view returns (...)`

Events:

```solidity
event BatchCreated(bytes32 indexed batchIdHash, address indexed beekeeper, string metadataCID, bytes32 metadataHash);
event HarvestRegistered(bytes32 indexed batchIdHash, uint64 harvestTimestamp, uint32 quantityGrams);
event ProcessingRegistered(bytes32 indexed batchIdHash, address indexed processor, string metadataCID);
event LabVerified(bytes32 indexed batchIdHash, address indexed lab, bytes32 labReportHash);
event Packaged(bytes32 indexed batchIdHash, address indexed processor, string metadataCID);
event CustodyTransferred(bytes32 indexed batchIdHash, address indexed from, address indexed to, uint8 status);
event RetailRegistered(bytes32 indexed batchIdHash, address indexed retailer);
event BatchRecalled(bytes32 indexed batchIdHash, address indexed by, string reasonCID);
event BatchRejected(bytes32 indexed batchIdHash, address indexed by, string reasonCID);
```

Judges inspect events on Amoy Polygonscan by opening the transaction hash, then the "Logs" tab, then matching `BatchCreated`/`LabVerified`/`CustodyTransferred` event values with the app's batch ID hash and CID.

## 11. QR Authentication

QR should contain:

```text
https://honey-chain.example/verify?b=HC-2026-CL01-000123&n=<nonce>&sig=<backend_signature>
```

Verification flow:

```text
Consumer scans QR
  -> verification web page opens
  -> backend validates batch ID, nonce, and signature
  -> backend queries PostgreSQL for operational record
  -> backend reads smart contract using RPC
  -> backend fetches IPFS CID metadata
  -> backend recomputes metadata/certificate hashes
  -> page shows authenticity status and explorer/IPFS links
```

Anti-fake design:

- Batch IDs are random or sequential with a signed nonce, not guessable alone.
- QR payload is signed by backend using HMAC/Ed25519.
- Contract lookup must find the batch hash.
- The app displays contract address, transaction hash, and IPFS CID.
- Revoked/recalled batches show a red status.
- Duplicate scans are logged off-chain with approximate region/time to flag cloned QR circulation.
- Static QR is acceptable for batch-level proof; item-level anti-cloning needs unique bottle serials.
- Dynamic QR can rotate short-lived access tokens but requires online verification.

QR cloning limitation: if an attacker copies a valid QR onto fake bottles, blockchain still verifies the original record. Detecting physical cloning needs item-level serials, tamper-evident labels, duplicate scan analytics, and retail chain control.

## 12. AI Architecture

### Disease Detection

| Model | Pros | Cons | Recommendation |
|---|---|---|---|
| YOLO | Localizes mites/disease signs; good demo visual | Needs bounding-box labels | Use only for Varroa/object labels |
| EfficientNet-B0 | Strong accuracy per parameter | Slightly heavier than MobileNet | Best classifier MVP |
| ResNet-18/50 | Simple baseline | Larger/slower | Use as baseline |
| MobileNetV3 | Mobile-friendly | May underperform EfficientNet | Good on-device option |
| ViT | Strong with large data | Data-hungry | Do not use for MVP |

MVP:

- Input: bee image, 224x224 RGB.
- Output: class probabilities: healthy, varroa/parasite suspected, pollen carrier, other/uncertain. Only include classes supported by chosen dataset.
- Pipeline: split train/val/test, augment, class-weight, train EfficientNet-B0, export ONNX/TFLite optional.
- Threshold: if confidence < 0.70, output "uncertain; manual inspection required."
- API: `POST /disease-detection` multipart image returns `prediction`, `confidence`, `model_version`, `inference_timestamp`, `evidence_image_hash`.

### Colony Health Prediction

Scientifically defensible signals:

- Sudden hive weight drop: possible theft, swarm, feeding/harvest, sensor issue.
- Daily weight gain trend: nectar flow and colony productivity proxy.
- Temperature/humidity out of expected range: stress risk.
- Acoustic frequency/activity changes: possible queenlessness/swarming research signal, but needs careful calibration.
- Weather mismatch: low activity expected during rain/wind/high heat.

Speculative claims to avoid:

- "AI detects all diseases from temperature/humidity alone."
- "Blockchain guarantees organic/pure honey."
- "Yield prediction is accurate without local historical yield labels."

### Honey Yield Prediction

Use XGBoost for MVP because it handles tabular features well with small datasets, missing values, non-linear interactions, and explainability through feature importance. Avoid LSTM/Temporal Transformer until there is enough time-series data.

Features:

- 7/14/30-day hive weight trend
- Temperature/humidity averages and anomalies
- Rainfall/wind/pressure from weather API
- Season/month
- Region
- Flowering/forage proxy
- Colony strength manual score
- Historical harvest quantity

Output:

- Expected yield range
- Confidence band
- Top contributing factors

## 13. IoT Architecture

Minimum viable hardware:

| Component | Measures | Why it matters | Protocol | Frequency | India cost estimate |
|---|---|---|---|---|---|
| ESP32 DevKit | Controller + Wi-Fi | Low-cost edge gateway | Wi-Fi, I2C, GPIO | 1-5 min publish | Rs 300-600 |
| BME280 | Temperature, humidity, pressure | Hive environment and weather context | I2C/SPI | 1-5 min | Rs 250-600 |
| Load cell 20-50 kg | Hive weight | Honey accumulation/harvest/swarm signal | Analog via HX711 | 5-15 min | Rs 400-1,500 |
| HX711 | Load cell amplifier | Converts strain gauge signal | GPIO serial | With load cell | Rs 100-250 |
| Optional NEO-6M GPS | Location | Deployment proof; not needed if app records site GPS | UART | Setup-only | Rs 500-900 |
| Optional camera | Bee images | Disease screening | ESP32-CAM/Wi-Fi | Manual/triggered | Rs 500-1,000 |
| Optional microphone | Hive acoustics | Swarm/queenlessness research | I2S/ADC | High rate, edge features | Rs 150-600 |

Recommended MVP: **ESP32 + BME280 + load cell + HX711**. Use the phone/app for GPS and camera upload. This avoids unnecessary wiring and power draw.

Wiring:

- BME280 VCC to 3.3V, GND, SDA GPIO21, SCL GPIO22.
- HX711 VCC, GND, DT GPIO4, SCK GPIO5; load cell E+/E-/A+/A- to HX711.
- ESP32 publishes JSON to MQTT: `honeychain/hives/{hiveId}/telemetry`.

Payload:

```json
{
  "hiveId": "HIVE-001",
  "deviceId": "ESP32-001",
  "temperatureC": 34.2,
  "humidityPct": 61.8,
  "pressureHPa": 1009.4,
  "weightKg": 27.35,
  "batteryPct": 84,
  "timestamp": "2026-09-05T10:30:00+05:30"
}
```

## 14. Backend Architecture

Use FastAPI because it fits Python AI inference, quick API development, async MQTT/RPC integration, and simple OpenAPI docs.

Services:

- API service: FastAPI, SQLAlchemy, Alembic, Pydantic.
- Worker service: Celery/RQ optional for contract submissions and IPFS uploads.
- MQTT broker: Mosquitto.
- DB: PostgreSQL.
- Blockchain client: `web3.py` or Node signer service with `ethers`.
- AI service: PyTorch model loaded behind FastAPI route.
- Storage service: Pinata API wrapper.

API endpoints:

| Endpoint | Request | Response | Auth | DB | Blockchain |
|---|---|---|---|---|---|
| `POST /beekeeper` | profile, region, wallet | beekeeper id | Admin/JWT | insert beekeeper | grant role optional |
| `POST /hive` | beekeeper id, region, device id | hive id | Beekeeper/JWT | insert hive | no |
| `POST /sensor-data` | telemetry JSON | accepted + reading id | device token | insert reading | optional daily hash |
| `POST /disease-detection` | image upload | prediction + confidence | beekeeper/JWT | insert inference | no; hash later in metadata |
| `POST /harvest` | hive id, date, quantity | harvest id | beekeeper/JWT | insert harvest | no |
| `POST /batch` | harvest id, metadata | batch id, tx hash, CID | beekeeper/JWT | insert batch | createBatch |
| `POST /lab-verification` | batch id, certificate file/hash | status, tx hash | lab/JWT | insert certificate | verifyLab |
| `POST /batch/{id}/transfer` | to actor, stage | tx hash | custodian/JWT | update custody | transferCustody |
| `GET /batch/{id}` | id | full operational record | internal/JWT | read | read contract |
| `GET /verify/{batchId}` | signed query params | consumer proof JSON | public | read safe fields | read contract |

## 15. Database Design

Tables:

- `actors(id, role, name, region, wallet_address, kyc_status, created_at)`
- `beekeepers(actor_id, cooperative_id, village, district, state)`
- `hives(id, beekeeper_id, device_id, region_public, gps_encrypted, created_at)`
- `sensor_readings(id, hive_id, ts, temperature_c, humidity_pct, pressure_hpa, weight_kg, battery_pct, source, is_simulated)`
- `ai_inferences(id, hive_id, batch_id, model_version, input_hash, prediction, confidence, created_at)`
- `harvests(id, hive_id, harvest_date, quantity_g, floral_source, notes)`
- `batches(id, batch_code, batch_hash, harvest_id, status, metadata_cid, metadata_hash, contract_address, create_tx_hash, current_custodian_id)`
- `certificates(id, batch_id, lab_actor_id, certificate_hash, cid, tx_hash, created_at)`
- `custody_events(id, batch_id, from_actor_id, to_actor_id, stage, tx_hash, created_at)`
- `qr_tokens(id, batch_id, nonce_hash, signature, active, scan_count, created_at)`
- `qr_scans(id, qr_token_id, scanned_at, ip_region, user_agent, status)`

## 16. IPFS Architecture

Use Pinata for MVP because it provides simple authenticated uploads, pin management, and gateway retrieval.

Metadata JSON:

```json
{
  "batchCode": "HC-2026-CL01-000123",
  "beekeeperPublicName": "KVIC Cluster CL01 Beekeeper 07",
  "region": "Wardha, Maharashtra",
  "honeyType": "Multiflora",
  "harvestDate": "2026-09-05",
  "quantityGrams": 25000,
  "labReportHash": "0x...",
  "iotSummary": {
    "period": "2026-08-25/2026-09-05",
    "avgTempC": 34.1,
    "avgHumidityPct": 62.3,
    "weightGainKg": 8.4
  },
  "aiSummary": {
    "modelVersion": "bee-health-efficientnet-b0-v0.1",
    "result": "healthy",
    "confidence": 0.86
  }
}
```

Process:

1. Build metadata JSON from DB.
2. Compute SHA-256 hash.
3. Upload JSON/certificate to Pinata.
4. Receive IPFS CID.
5. Store CID + hash on-chain.
6. On verification, retrieve CID and recompute hash.

Docs:

- IPFS docs: https://docs.ipfs.tech/
- IPFS content addressing: https://docs.ipfs.tech/concepts/content-addressing/
- Pinata docs: https://docs.pinata.cloud/
- Pinata file upload API: https://docs.pinata.cloud/api-reference/endpoint/ipfs/pin-file-to-ipfs

## 17. Security

| Threat | Attack | Mitigation |
|---|---|---|
| Private key theft | Attacker submits fake events | Use env secrets, hardware wallet/admin multisig for production, role separation |
| Fake beekeeper | Unauthorized actor registers batches | Admin/KVIC approval, KYC, AccessControl |
| Fake sensor data | Device posts invented telemetry | Device tokens, signed payloads, calibration, anomaly detection |
| Sensor spoofing | Heat/weight manipulation | Tamper-evident housing, cross-check weight/weather/activity |
| QR cloning | Valid QR copied to fake bottle | Unique serial QR, duplicate scan alerts, revocation, tamper labels |
| Database manipulation | Backend alters records | Blockchain hashes/CIDs cross-check database |
| Contract bugs | Unauthorized update/reentrancy | OpenZeppelin, tests, least privilege, no external calls in core flow |
| Oracle manipulation | Weather/API data spoofed | Store API source/time, compare multiple weather APIs for production |
| AI manipulation | Adversarial image or wrong model | Confidence thresholds, manual review, model versioning |
| Fake lab certificate | User uploads fake PDF | Authorized lab role signs/verifies hash, lab registry |
| IPFS replacement | Metadata swapped | CID changes if content changes; verify hash on-chain |
| Replay attack | Old QR/API request reused | Nonces, active token table, signature expiry if dynamic QR |

## 18. Authenticity vs Data Integrity

Blockchain gives data integrity: after a certificate hash, metadata CID, and custody event are recorded, they cannot be silently changed without a visible new transaction.

Blockchain does not physically test honey. Authenticity requires:

- FSSAI-aligned honey standards.
- Laboratory tests for sugars/adulterants, moisture, HMF, acidity, conductivity, etc.
- Advanced testing where needed, such as NMR/isotope methods.
- Pollen/melissopalynology for floral/geographic claims.
- Authorized lab identity and certificate chain.
- Tamper-evident packaging and custody records.

Honey Chain should say: **"Blockchain verifies the integrity and provenance of authenticity evidence."** It should not say: "Blockchain proves honey is pure."

## 19. Judge-Verifiable Proof System

Demo proof chain:

```text
Physical Honey Batch
        |
        v
Batch ID
        |
        v
QR Code
        |
        v
Application
        |
        v
Backend API
        |
        v
Polygon Amoy Transaction
        |
        v
Smart Contract Event
        |
        v
IPFS CID
        |
        v
Immutable Metadata Hash
```

Judge test:

1. Create beekeeper.
2. Register hive.
3. Show live sensor data timestamp changing.
4. Upload bee image and run AI inference.
5. Create harvest.
6. Create honey batch.
7. Backend uploads metadata to IPFS.
8. Backend submits smart-contract transaction.
9. App shows transaction hash, block number, contract address.
10. Judge opens Amoy Polygonscan and sees event.
11. App generates QR.
12. Judge scans QR on phone.
13. Verification page fetches live backend, contract, and IPFS data.
14. Judge creates a second batch and sees a different transaction/hash/CID.
15. Judge changes one character in batch ID and verification fails.

## 20. Exact Technology Stack

- Frontend: Flutter, docs https://docs.flutter.dev/
- Backend: FastAPI, docs https://fastapi.tiangolo.com/
- Database: PostgreSQL, docs https://www.postgresql.org/docs/
- Migrations: Alembic, docs https://alembic.sqlalchemy.org/
- MQTT: Eclipse Mosquitto, docs https://mosquitto.org/documentation/
- Blockchain: Polygon Amoy, docs https://docs.polygon.technology/
- Smart contract: Solidity, docs https://docs.soliditylang.org/
- Contract library: OpenZeppelin Contracts, docs https://docs.openzeppelin.com/contracts/
- Development: Hardhat + Hardhat Ignition, docs https://hardhat.org/docs
- Wallet: MetaMask, docs https://support.metamask.io/
- IPFS: Pinata, docs https://docs.pinata.cloud/
- AI: PyTorch, torchvision, scikit-learn, XGBoost
- Deployment: Docker Compose locally; Render/Railway for API; Vercel/Netlify or Flutter web static hosting for frontend

## 21. Exact Setup Instructions

Prerequisites:

```bash
node --version
npm --version
python3 --version
git --version
```

Create repo:

```bash
mkdir honey-chain
cd honey-chain
mkdir frontend backend blockchain ai iot docs tests scripts
git init
```

Backend:

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install fastapi uvicorn sqlalchemy psycopg[binary] alembic pydantic python-multipart web3 requests python-jose passlib[bcrypt]
uvicorn app.main:app --reload
```

Blockchain:

```bash
cd blockchain
npm init -y
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox
npm install @openzeppelin/contracts dotenv
npx hardhat --init
```

Frontend:

```bash
flutter create frontend
cd frontend
flutter pub add http mobile_scanner qr_flutter provider go_router
flutter run -d chrome
```

## 22. Exact Polygon Deployment

1. Install MetaMask: https://metamask.io/
2. Create wallet; write seed phrase offline; never commit private key.
3. Add Polygon Amoy:
   - Network: Polygon Amoy
   - Chain ID: `80002`
   - Currency: `POL`/test token shown by wallet
   - Explorer: https://amoy.polygonscan.com/
   - Use the current RPC from Polygon docs or a provider such as Alchemy/Infura.
4. Get Amoy test tokens from https://faucet.polygon.technology/.
5. Create `.env` in `blockchain/`:

```text
AMOY_RPC_URL=https://polygon-amoy.g.alchemy.com/v2/YOUR_KEY
PRIVATE_KEY=your_test_wallet_private_key_without_0x
POLYGONSCAN_API_KEY=your_polygonscan_key
```

6. Install:

```bash
cd blockchain
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox
npm install @openzeppelin/contracts dotenv
```

7. Configure `hardhat.config.ts`:

```ts
import "@nomicfoundation/hardhat-toolbox";
import "dotenv/config";

export default {
  solidity: "0.8.28",
  networks: {
    amoy: {
      url: process.env.AMOY_RPC_URL!,
      accounts: [process.env.PRIVATE_KEY!],
    },
  },
  etherscan: {
    apiKey: {
      polygonAmoy: process.env.POLYGONSCAN_API_KEY!,
    },
  },
};
```

8. Compile:

```bash
npx hardhat compile
```

9. Deploy with Ignition:

```bash
npx hardhat ignition deploy ignition/modules/HoneyChain.ts --network amoy
```

10. Record contract address in `docs/deployment-amoy.json`.
11. Verify:

```bash
npx hardhat verify --network amoy <CONTRACT_ADDRESS>
```

12. Create/read batch via script:

```bash
npx hardhat run scripts/createBatch.ts --network amoy
npx hardhat run scripts/readBatch.ts --network amoy
```

13. Open transaction:

```text
https://amoy.polygonscan.com/tx/<TX_HASH>
```

Docs:

- Hardhat: https://hardhat.org/docs
- Hardhat Ignition: https://hardhat.org/ignition/docs/getting-started
- OpenZeppelin AccessControl: https://docs.openzeppelin.com/contracts/access-control
- Polygonscan verification/API: https://docs.polygonscan.com/

## 23. Exact IPFS Setup

1. Create Pinata account: https://www.pinata.cloud/
2. Create API key in Pinata dashboard.
3. Store keys in backend `.env`:

```text
PINATA_JWT=your_pinata_jwt
PINATA_GATEWAY=https://gateway.pinata.cloud/ipfs/
```

4. Upload metadata:

```python
import hashlib, json, requests, os

metadata = {"batchCode": "HC-2026-CL01-000123", "harvestDate": "2026-09-05"}
body = json.dumps(metadata, sort_keys=True).encode()
metadata_hash = "0x" + hashlib.sha256(body).hexdigest()

res = requests.post(
    "https://api.pinata.cloud/pinning/pinJSONToIPFS",
    headers={"Authorization": f"Bearer {os.environ['PINATA_JWT']}"},
    json={"pinataContent": metadata},
    timeout=30,
)
cid = res.json()["IpfsHash"]
```

5. Store `cid` and `metadata_hash` on-chain.
6. Retrieve:

```text
https://gateway.pinata.cloud/ipfs/<CID>
```

7. Recompute hash and compare with smart-contract value.

## 24. Repository Structure

```text
honey-chain/
├── frontend/                 # Flutter app and consumer verification UI
├── backend/
│   ├── app/
│   │   ├── api/              # FastAPI routers
│   │   ├── models/           # SQLAlchemy models
│   │   ├── services/         # blockchain, IPFS, AI, QR services
│   │   └── main.py
│   ├── alembic/              # DB migrations
│   └── tests/
├── blockchain/
│   ├── contracts/            # HoneyChain.sol
│   ├── ignition/modules/     # deployment module
│   ├── scripts/              # create/read/verify scripts
│   └── test/                 # Hardhat contract tests
├── ai/
│   ├── disease_detection/    # training, inference, model card
│   └── yield_prediction/     # XGBoost pipeline
├── iot/
│   ├── esp32/                # Arduino/PlatformIO firmware
│   └── simulator/            # clearly labeled simulated stream
├── datasets/                 # download scripts and metadata only
├── docs/                     # architecture, demo proof, deployments
├── scripts/                  # seed/demo orchestration
├── docker-compose.yml
├── README.md
└── .env.example
```

## 25. Testing Strategy

Blockchain tests:

- Creates a batch and emits `BatchCreated`.
- Rejects duplicate batch ID.
- Rejects unauthorized lab verification.
- Transfers custody only from current custodian.
- Recalls batch and makes status invalid for consumer.
- Returns expected metadata CID/hash.

Backend tests:

- Request validation for every endpoint.
- JWT/role checks.
- DB transaction rollback when blockchain transaction fails.
- Verify endpoint rejects invalid signature/nonce.
- IPFS hash mismatch fails verification.

AI tests:

- Held-out accuracy and macro F1.
- Per-class precision/recall.
- Confusion matrix exported to docs.
- Low confidence returns "uncertain."
- Model card lists dataset and limitations.

IoT tests:

- Valid telemetry accepted.
- Missing readings rejected.
- Sensor values outside physical limits flagged.
- Simulator marks `is_simulated=true`.
- Device token required.

QR tests:

- Valid QR verifies.
- Modified batch ID fails.
- Modified nonce/signature fails.
- Revoked batch displays recalled.
- Duplicate scan increments scan count and can trigger warning.

## 26. MVP Scope

Must have:

- Deployed Polygon Amoy smart contract.
- Real transaction for batch creation.
- Contract address and transaction hash shown.
- QR verification page queries backend + blockchain.
- Metadata uploaded to IPFS.
- Bee image AI inference with real model and model version.
- ESP32 sensor stream, or simulator clearly labeled if hardware fails.
- Invalid QR demo.

Should have:

- Lab certificate hash flow.
- Transfer from beekeeper to processor/retailer.
- Duplicate scan analytics.
- Model card and dataset links.

Nice to have:

- YOLO Varroa bounding boxes.
- Item-level bottle QR serials.
- Offline mobile sync.
- Multiple weather API cross-checking.

Do not build for MVP:

- Token/cryptocurrency payments.
- Full marketplace.
- Enterprise Hyperledger network.
- Complex drone/satellite analytics.
- Claims of automatic purity detection.

## 27. Implementation Roadmap

| Phase | Task | Technology | Command/tool | Expected output | Done when |
|---|---|---|---|---|---|
| 1 Blockchain | Contract + tests | Solidity/Hardhat | `npx hardhat test` | Passing tests | Events verified locally |
| 2 Backend | API skeleton | FastAPI | `uvicorn app.main:app --reload` | OpenAPI docs | Endpoints validate |
| 3 Database | Schema | PostgreSQL/Alembic | `alembic upgrade head` | Tables | Migrations reproducible |
| 4 AI | Train classifier | PyTorch | `python train.py` | model + metrics | Model card generated |
| 5 IoT | Firmware/simulator | ESP32/MQTT | PlatformIO/Arduino | Live telemetry | Dashboard updates |
| 6 QR | Signed QR | Flutter/FastAPI | QR route | Scan opens proof page | Tampered URL fails |
| 7 Integration | Batch creation | Web3.py/ethers | create batch flow | tx hash + CID | Real explorer link |
| 8 Testing | Full suite | Pytest/Hardhat | `pytest`, `npx hardhat test` | pass/fail report | CI green |
| 9 Deployment | API/frontend | Docker/Render/Vercel | Docker Compose | Public URL | Judge can access |
| 10 Demo | Scripted proof | All | seed/demo scripts | 5-7 minute demo | Second batch changes proof |

## 28. 5-7 Minute Demo Script

1. Register beekeeper: show wallet address and backend-created beekeeper ID.
2. Register hive: show hive ID and device ID.
3. Show live IoT data: temperature/humidity/weight timestamp changes in dashboard.
4. Upload bee image: run model, show prediction, confidence, model version, input hash.
5. Create harvest: enter quantity, floral type, date.
6. Create blockchain batch: backend generates batch ID, metadata JSON, IPFS CID.
7. Show Polygon transaction hash: click "Verify on Blockchain."
8. Open Amoy Polygonscan: show contract address, block, event logs.
9. Generate QR: display and print/screen-share code.
10. Scan QR from another phone: page loads live verification.
11. Show provenance: beekeeper, region, harvest, lab hash, IPFS CID, status.
12. Show lab evidence: PDF/hash/CID and lab role address.
13. Demonstrate fake QR: alter one character in batch ID or signature; verification fails.
14. Show yield prediction: explain it is prototype/local-data dependent and display factors.

## 29. Judge Verification Checklist

- Contract address opens on Amoy Polygonscan.
- Transaction hash timestamp matches demo time.
- `BatchCreated` event contains batch hash shown in app.
- IPFS CID opens metadata JSON.
- Metadata SHA-256 equals on-chain hash.
- QR URL contains batch ID + nonce + signature.
- Invalid signature fails.
- IoT timestamp changes live.
- AI inference timestamp and input hash change when a new image is uploaded.
- Creating another batch produces a different transaction, CID, and QR.
- API `GET /verify/{batchId}` returns dynamic data.
- GitHub contains contract, deployment script, tests, dataset references, model card, API docs, and demo instructions.

Add a visible **Verify on Blockchain** button beside every batch.

## 30. Final Deliverables

Software:

- Flutter app
- FastAPI backend
- PostgreSQL migrations
- Docker Compose

Hardware:

- ESP32
- BME280
- Load cell
- HX711
- Power bank/battery

Blockchain:

- Deployed Polygon Amoy contract
- Contract address
- Verified source on explorer
- Deployment script
- Test transactions

AI:

- Model file
- Training notebook/script
- Metrics report
- Model card

Dataset:

- Dataset source links
- License notes
- Download instructions
- No fabricated real-world claims

QR:

- Signed QR generator
- Consumer verification page
- Invalid QR demo

Documentation:

- Architecture diagram
- API docs
- Smart-contract docs
- Demo script
- Security analysis

Presentation slides should show:

- Problem and why trust is broken
- Authenticity vs blockchain integrity
- Architecture diagram
- Live proof chain
- Blockchain explorer screenshot/link
- IPFS CID/hash verification
- AI/IoT evidence
- MVP scope and production path

## 31. Risks and Limitations

- Public bee disease datasets are incomplete for all requested disease classes.
- Yield prediction is not production-valid without local historical yield labels.
- Blockchain cannot prevent QR cloning by itself.
- Lab verification requires trusted labs and real certificate workflows.
- Rural connectivity may require offline-first sync.
- Sensor calibration and tamper resistance are non-trivial.
- Testnet transactions prove technical behavior, not production legal validity.

## 32. Sources / References

Government and India honey ecosystem:

- KVIC: https://www.kvic.gov.in/
- National Bee Board: https://nbb.gov.in/
- Madhukranti portal: https://madhukrantiportal.in/
- FSSAI: https://www.fssai.gov.in/
- FSSAI regulations: https://fssai.gov.in/cms/food-safety-and-standards-regulations.php
- Ministry of Agriculture and Farmers Welfare: https://agricoop.nic.in/
- CSE honey/adulteration coverage: https://www.cseindia.org/

Blockchain and smart contracts:

- Bitcoin whitepaper: https://bitcoin.org/bitcoin.pdf
- Bitcoin developer docs: https://developer.bitcoin.org/
- Ethereum developer docs: https://ethereum.org/en/developers/docs/
- Ethereum networks/testnets: https://ethereum.org/en/developers/docs/networks/
- Polygon docs: https://docs.polygon.technology/
- Polygon faucet: https://faucet.polygon.technology/
- Amoy Polygonscan: https://amoy.polygonscan.com/
- Avalanche docs: https://docs.avax.network/
- BNB Chain docs: https://docs.bnbchain.org/
- Hyperledger Fabric docs: https://hyperledger-fabric.readthedocs.io/
- Solidity docs: https://docs.soliditylang.org/
- OpenZeppelin Contracts: https://docs.openzeppelin.com/contracts/
- Hardhat docs: https://hardhat.org/docs
- Hardhat Ignition: https://hardhat.org/ignition/docs/getting-started
- MetaMask support/docs: https://support.metamask.io/

IPFS:

- IPFS docs: https://docs.ipfs.tech/
- IPFS content addressing: https://docs.ipfs.tech/concepts/content-addressing/
- Pinata docs: https://docs.pinata.cloud/
- Pinata upload API: https://docs.pinata.cloud/api-reference/endpoint/ipfs/pin-file-to-ipfs

Backend, IoT, AI:

- FastAPI docs: https://fastapi.tiangolo.com/
- PostgreSQL docs: https://www.postgresql.org/docs/
- Docker Compose docs: https://docs.docker.com/compose/
- Eclipse Mosquitto docs: https://mosquitto.org/documentation/
- ESP-IDF docs: https://docs.espressif.com/projects/esp-idf/en/latest/esp32/
- PyTorch docs: https://pytorch.org/docs/stable/index.html
- XGBoost docs: https://xgboost.readthedocs.io/
- Ultralytics YOLO docs: https://docs.ultralytics.com/

Datasets and APIs:

- Honey Bee Annotated Images: https://www.kaggle.com/datasets/jenny18/honey-bee-annotated-images
- Bee vs Wasp dataset: https://www.kaggle.com/datasets/jerzydziewierz/bee-vs-wasp
- VarroaDataset: https://zenodo.org/records/4085044
- Roboflow bee datasets search: https://universe.roboflow.com/search?q=bee%20disease
- OpenWeather API: https://openweathermap.org/api
- Open-Meteo API: https://open-meteo.com/en/docs
- NASA POWER API: https://power.larc.nasa.gov/docs/services/api/

Existing solutions:

- IBM Food Trust: https://www.ibm.com/products/supply-chain-intelligence-suite/food-trust
- TE-Food: https://te-food.com/
- OpenSC: https://opensc.org/
- BroodMinder: https://broodminder.com/
- Arnia: https://www.arnia.co.uk/
- BeeHero: https://www.beehero.io/
- Beewise: https://beewise.ag/

Research paper matrix:

| # | Paper | Authors/year | DOI/link | Dataset | Method | Results | Use in Honey Chain | Limitation |
|---|---|---|---|---|---|---|---|---|
| 1 | An agri-food supply chain traceability system for China based on RFID & blockchain technology | Feng Tian, 2016 | https://doi.org/10.1109/ICSSSM.2016.7538424 | Conceptual/case architecture | RFID + blockchain traceability | Shows blockchain can strengthen supply-chain record integrity | Use as baseline food traceability architecture | Not honey-specific; older blockchain stack |
| 2 | The rise of blockchain technology in agriculture and food supply chains | Kamilaris, Fonts, Prenafeta-Boldu, 2019 | https://doi.org/10.1016/j.tifs.2019.07.034 | Literature review | Systematic review | Identifies traceability/transparency benefits and integration barriers | Supports realistic blockchain scope | Review, not implementation |
| 3 | Future challenges on the use of blockchain for food traceability analysis | Galvez, Mejuto, Simal-Gandara, 2018 | https://doi.org/10.1016/j.trac.2018.08.011 | Literature review | Food traceability analysis | Emphasizes need for trusted input data and standards | Supports "blockchain is evidence integrity, not physical proof" | Does not solve oracle problem |
| 4 | Blockchain-based soybean traceability in agricultural supply chain | Salah, Nizamuddin, Jayaraman, Omar, 2019 | https://doi.org/10.1109/ACCESS.2019.2918000 | Smart-contract prototype | Ethereum smart contracts | Demonstrates event-based agri traceability | Reuse event/state pattern for batch custody | Soybean, not honey |
| 5 | Blockchain-based food supply chain traceability: a case study in the dairy sector | Casino et al., 2021 | https://doi.org/10.1016/j.ijpe.2020.107955 | Dairy case data | Blockchain traceability framework | Shows practical traceability workflow | Adapt off-chain/on-chain split | Dairy-specific compliance assumptions |
| 6 | Fujairah Honey Chain: A Blockchain Framework for Monitoring Honey Production | Published 2025 | https://doi.org/10.3390/info16080626 | Honey framework data/simulations | Blockchain + oracle + IoT/ML | Reports sub-USD transaction cost target and oracle validation concept | Closest honey-blockchain reference | UAE-specific; token design may be too much for SIH MVP |
| 7 | Trustworthy regulatory traceability model for honey supply chain under blockchain architecture | Yang Wanlong, Chen Lin, 2024 | https://doi.org/10.19734/j.issn.1001-3695.2023.07.0292 | Simulation | Blockchain + IPFS + privacy architecture | Proposes layered storage and regulator traceability | Supports IPFS + on-chain hash design | Chinese-language article; implementation details need review |
| 8 | Honey Traceability and Authenticity. Review of Current Methods Most Used to Face this Problem | Danieli, Lazzari, 2022 | https://doi.org/10.2478/jas-2022-0012 | Review of authentication methods | Analytical methods, melissopalynology, chemometrics, traceability | Shows authenticity needs lab/analytical evidence | Supports FSSAI/lab evidence section | Review, not an app prototype |
| 9 | Precision apiculture system: honey traceability from hive to spoon | Journal of Apicultural Research, 2024 | https://doi.org/10.1080/00218839.2024.2435223 | Sumadhu app pilot data | GPS, blockchain, ML, app-based traceability | India-relevant honey traceability pilot | Use as strongest India prior-art comparison | Closed details may require journal access |
| 10 | Toward an intelligent and efficient beehive: A survey of precision beekeeping systems and services | Hadjur, Ammar, Lefevre, 2022 | https://doi.org/10.1016/j.compag.2021.106604 | Literature review | Precision beekeeping systems survey | Maps sensors, architectures, ML layers | Supports IoT architecture decisions | Survey only |
| 11 | Application of continuous monitoring of honeybee colonies | Meikle, Holst, 2015 | https://doi.org/10.1007/s13592-014-0298-x | Continuous hive measurements literature | Hive weight, temperature, humidity, gas, traffic review | Establishes value and limits of continuous monitoring | Supports weight/temp/humidity MVP sensors | Not a modern deployed product |
| 12 | IoT Monitoring and Prediction Modeling of Honeybee Activity with Alarm | Andrijevic et al., 2022 | https://doi.org/10.3390/electronics11050783 | 20 days, 5-min sensor/bee-counter data; public GitLab noted in paper | IoT station + ARIMA/Prophet/LSTM | Reports bee activity prediction with low hourly error in study context | Supports alarm/prediction design and dataset strategy | Activity prediction, not honey-yield prediction |
| 13 | An Internet of Things-Based Low-Power Integrated Beekeeping Safety and Conditions Monitoring System | Kontogiannis, 2019 | https://doi.org/10.3390/inventions4030052 | System prototype | Low-power IoT + LoRaWAN | Demonstrates condition/safety monitoring architecture | Supports ESP32/LoRa-style rural deployment path | Broader system than MVP |
| 14 | Visual Diagnosis of the Varroa Destructor Parasitic Mite in Honeybees Using Object Detector Techniques | Bilik et al., 2021 | https://doi.org/10.3390/s21082764 | 600 annotated images | YOLOv5, SSD, Deep SVDD | Highest F1 up to 0.874 infected bee detection and 0.714 mite detection | Supports YOLO Varroa optional module | Small custom dataset |
| 15 | Detection of Varroa destructor Infestation of Honeybees Based on Segmentation and Object Detection CNNs | Liu et al., 2023 | https://doi.org/10.3390/agriengineering5040102 | Bee farm image datasets | FCN segmentation + improved YOLOX | Improved detection compared with direct detectors | Supports segmentation before mite detection | Dataset may not be public |
| 16 | Buzzing with Intelligence: A Systematic Review of Smart Beehive Technologies | Sabic, Perkovic, Solic, et al., 2025 | https://doi.org/10.3390/s25175359 | Review of 135 publications | PRISMA review | Finds environmental/acoustic sensors common and dataset standardization gaps | Supports limitations and multimodal roadmap | Very recent; use as strategic overview |

Priority papers for slides: 6, 8, 9, 10, 12, 14, 16 plus one general blockchain-food survey.
