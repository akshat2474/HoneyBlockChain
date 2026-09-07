# The HoneyChain Master Architecture & Code Explanation

This document serves as the complete, excruciatingly detailed breakdown of everything we built for the HoneyChain SIH prototype. It explains every architectural decision, every line of logic, and exactly how the data flows from the beekeeper's phone to the decentralized blockchain.

---

## 1. Architectural Decisions: Why We Chose This Tech Stack

To build a traceability system for the KVIC Honey Mission, we needed a stack that was fast, cheap, verifiable, and mobile-friendly.

*   **Polygon Amoy (Blockchain):** We chose Polygon over Ethereum Mainnet because Ethereum is too slow and expensive for frequent supply-chain events. We chose Polygon Amoy (the testnet) for the hackathon because it provides the exact same EVM (Ethereum Virtual Machine) compatibility as Mainnet, but tokens are free.
*   **IPFS / Pinata (Storage):** Storing a 2MB image or a large JSON file directly on a blockchain costs thousands of dollars in gas fees. Instead, we use IPFS (InterPlanetary File System). IPFS is a decentralized hard drive. Pinata is a service that uploads our files to IPFS and gives us a `CID` (Content Identifier hash). We store *only this tiny hash* on the blockchain.
*   **Python FastAPI (Backend):** We needed a backend to act as a secure bridge. If we put the blockchain Private Key directly into the Flutter app, a hacker could extract it and forge honey batches. FastAPI securely holds the private key, handles the IPFS uploads, and signs the blockchain transactions on behalf of the mobile app.
*   **Flutter (Frontend):** Allows us to build the Beekeeper app for both Android and Web simultaneously with one codebase.

---

## 2. The Smart Contract (`HoneyChain.sol`)

The smart contract is the absolute core of the project. It is the immutable ledger that proves the honey is real. Let's break it down function by function.

### A. The Setup & Access Control
```solidity
import "@openzeppelin/contracts/access/AccessControl.sol";

contract HoneyChain is AccessControl, Pausable {
    bytes32 public constant BEEKEEPER_ROLE = keccak256("BEEKEEPER_ROLE");
    bytes32 public constant LAB_ROLE = keccak256("LAB_ROLE");
    // ...
```
**Why this decision?** We imported `AccessControl` from OpenZeppelin, which is the gold standard for blockchain security. We do not want just *anyone* creating a batch of honey. We defined specific roles (`BEEKEEPER_ROLE`, `LAB_ROLE`). The blockchain will literally reject a transaction if the wallet calling it doesn't have the correct role.

### B. The Data Structure (`HoneyBatch`)
```solidity
struct HoneyBatch {
    bytes32 batchIdHash;
    address beekeeper;
    address currentCustodian;
    uint64 harvestTimestamp;
    uint32 quantityGrams;
    BatchStatus status;
    string metadataCID;
    bytes32 metadataHash;
    bytes32 labReportHash;
    bool labVerified;
}
mapping(bytes32 => HoneyBatch) public batches;
```
**Why this decision?** Notice what is *missing* here: there is no location data, no sensor temperatures, and no images. 
Instead, we only store:
1.  **`metadataCID`**: The link to the IPFS file containing all the heavy sensor/location data.
2.  **`metadataHash`**: A cryptographic SHA-256 hash of that IPFS data. If someone somehow alters the IPFS file, the hash will change, and the blockchain will prove the data was tampered with.
3.  **`mapping(bytes32 => HoneyBatch)`**: This is essentially a database table where the key is the Batch ID, and the value is the struct containing the batch details.

### C. Function: `createBatch`
```solidity
function createBatch(
    bytes32 _batchIdHash,
    uint32 _quantityGrams,
    uint64 _harvestTimestamp,
    string memory _metadataCID,
    bytes32 _metadataHash
) external onlyRole(BEEKEEPER_ROLE) whenNotPaused {
    require(batches[_batchIdHash].createdAt == 0, "Batch already exists");

    batches[_batchIdHash] = HoneyBatch({
        // ... initializes the struct variables
    });

    emit BatchCreated(_batchIdHash, msg.sender, _metadataCID, _metadataHash);
}
```
**Breakdown:**
*   `external`: This function can only be called from outside the contract (by our Python backend).
*   `onlyRole(BEEKEEPER_ROLE)`: The security guard. It checks the wallet address making the transaction.
*   `require(...)`: Ensures we don't accidentally overwrite an existing batch.
*   `emit BatchCreated(...)`: **This is crucial.** Emitting an "Event" writes this data to the blockchain's permanent log (which is very cheap). When a judge scans the QR code later, your app will search Polygonscan for this exact event to prove it happened.

---

## 3. The Deployment Infrastructure (Hardhat)

You might wonder why we needed the `hardhat.config.ts` and `ignition/modules/HoneyChain.ts` files. 

Solidity code is just human-readable text. The Polygon blockchain only understands binary "Bytecode". 
1.  **`npx hardhat compile`**: This took our Solidity text and translated it into machine Bytecode.
2.  **`hardhat.config.ts`**: We gave it your Alchemy RPC URL and your Private Key so it knew *where* to send the code and *who* was paying the gas fee.
3.  **`npx hardhat ignition deploy`**: This securely packaged the Bytecode, signed it with your Private Key, and pushed it to Polygon Amoy.

---

## 4. The Python Backend (`main.py`)

The FastAPI backend is the engine of the operation. It receives simple JSON from the mobile app and turns it into highly complex cryptographic blockchain transactions.

### A. The IPFS Upload Function
```python
def upload_to_pinata(metadata_dict):
    url = "https://api.pinata.cloud/pinning/pinJSONToIPFS"
    headers = {"Authorization": f"Bearer {PINATA_JWT}"}
    response = requests.post(url, json={"pinataContent": metadata_dict}, headers=headers)
    return response.json()["IpfsHash"]
```
**Breakdown:** Before we touch the blockchain, we take all the heavy data (which later will include the ESP32 IoT sensor data) and upload it to Pinata. Pinata pins it to the global IPFS network and returns a hash that starts with `Qm...` (the CID).

### B. The Core Blockchain Logic (`/create-batch`)
```python
@app.post("/create-batch")
def create_batch(batch_req: HoneyBatchRequest):
    # 1. Prepare Data
    metadata = { "batchId": batch_req.batchId, "quantity": batch_req.quantityGrams ... }
    
    # 2. Cryptographic Hashing
    metadata_string = json.dumps(metadata, sort_keys=True)
    metadata_hash = hashlib.sha256(metadata_string.encode('utf-8')).hexdigest()
    
    # 3. Upload to IPFS
    cid = upload_to_pinata(metadata)
    
    # 4. Build the Blockchain Transaction
    tx = contract.functions.createBatch(
        batch_id_hash, batch_req.quantityGrams, timestamp, cid, metadata_bytes32
    ).build_transaction({
        'from': account.address,
        'nonce': w3.eth.get_transaction_count(account.address),
    })
    
    # 5. Sign and Send
    signed_tx = w3.eth.account.sign_transaction(tx, private_key=PRIVATE_KEY)
    tx_hash = w3.eth.send_raw_transaction(signed_tx.raw_transaction)
```
**Why this decision?** 
*   **Hashing (`hashlib.sha256`)**: We lock down the data before sending it. We take the exact JSON string and create a SHA-256 fingerprint of it. We send both the IPFS link AND the fingerprint to the blockchain. If a single comma changes in the IPFS file later, the fingerprint won't match, and the batch is flagged as fake.
*   **Nonces**: `w3.eth.get_transaction_count()` gets the number of transactions your wallet has ever sent. The blockchain requires this to prevent "replay attacks" (someone copying your transaction and submitting it twice).
*   **Signing**: `sign_transaction` mathematically signs the package using your Private Key. This proves to Polygon that the transaction is legitimately from the Admin wallet.

---

## 5. The Flutter Frontend (`main.dart`)

The frontend is the window into the system. 

```dart
final response = await http.post(
  Uri.parse('http://127.0.0.1:8000/create-batch'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'batchId': _batchIdController.text,
    'quantityGrams': int.parse(_quantityController.text),
    // ...
  }),
);
```
**Breakdown:** 
*   The Flutter app doesn't know anything about Web3, Blockchain, Gas fees, or IPFS. 
*   It simply captures the user's text inputs, formats them into a standard JSON dictionary, and fires them to `localhost:8000`. 
*   The State Management (`setState`) listens for the `200 OK` response from Python, and when it arrives, it updates the UI to show the `tx_hash` (Transaction Hash) and provides clickable buttons using the `url_launcher` package so the beekeeper can instantly verify their work on Polygonscan.

---

## 6. The Complete Data Flow Summary

To summarize the entire architecture from start to finish:

1.  **The Beekeeper** types `HC-001` and `5000 grams` into the Flutter App.
2.  **Flutter** packages this into JSON and POSTs it to the Python server.
3.  **Python** receives the JSON, formats it, and uploads it to **IPFS via Pinata**.
4.  **Pinata** returns a decentralized link (CID).
5.  **Python** cryptographically hashes the JSON, constructs a smart contract call, signs it with the Private Key, and fires it to **Polygon Amoy via Alchemy**.
6.  **Polygon** executes the `HoneyChain.sol` code. The code checks if the wallet has the `BEEKEEPER_ROLE`. It does. The code stores the CID and Hash permanently on the ledger and emits a `BatchCreated` event.
7.  **Python** receives the Transaction Hash from Polygon and sends it back to Flutter.
8.  **Flutter** displays a green success message and a link to the block explorer.

This system is entirely trustless, immutable, and exactly what enterprise supply chains use.
