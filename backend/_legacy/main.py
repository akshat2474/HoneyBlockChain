from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import os
import json
import requests
from web3 import Web3
from dotenv import load_dotenv
from eth_account import Account
import hashlib
from datetime import datetime

load_dotenv()

app = FastAPI(title="HoneyChain API")

RPC_URL = os.getenv("AMOY_RPC_URL")
PRIVATE_KEY = os.getenv("PRIVATE_KEY")
CONTRACT_ADDRESS = os.getenv("CONTRACT_ADDRESS")
PINATA_JWT = os.getenv("PINATA_JWT")

w3 = Web3(Web3.HTTPProvider(RPC_URL))
account = Account.from_key(PRIVATE_KEY)

abi_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../blockchain/artifacts/contracts/HoneyChain.sol/HoneyChain.json'))
try:
    with open(abi_path, 'r') as file:
        contract_json = json.load(file)
        contract_abi = contract_json['abi']
    contract = w3.eth.contract(address=CONTRACT_ADDRESS, abi=contract_abi)
except Exception as e:
    print(f"Warning: Could not load contract ABI from {abi_path}. Make sure you compiled the contract.")
    contract = None

class HoneyBatchRequest(BaseModel):
    batchId: str
    quantityGrams: int
    honeyType: str
    region: str


def upload_to_pinata(metadata_dict):
    """Uploads a JSON dictionary to Pinata IPFS and returns the CID"""
    url = "https://api.pinata.cloud/pinning/pinJSONToIPFS"
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {PINATA_JWT}"
    }
    response = requests.post(url, json={"pinataContent": metadata_dict}, headers=headers)
    
    if response.status_code == 200:
        return response.json()["IpfsHash"]
    else:
        raise Exception(f"Pinata upload failed: {response.text}")


@app.get("/")
def read_root():
    return {"status": "success", "message": "HoneyChain API is running!"}

@app.post("/create-batch")
def create_batch(batch_req: HoneyBatchRequest):
    if not contract:
        raise HTTPException(status_code=500, detail="Smart contract not loaded.")

    try:
        metadata = {
            "batchId": batch_req.batchId,
            "honeyType": batch_req.honeyType,
            "region": batch_req.region,
            "quantityGrams": batch_req.quantityGrams,
            "timestamp": datetime.utcnow().isoformat()
        }

        metadata_string = json.dumps(metadata, sort_keys=True)
        metadata_hash = hashlib.sha256(metadata_string.encode('utf-8')).hexdigest()
        metadata_bytes32 = Web3.to_bytes(hexstr=metadata_hash)

        cid = upload_to_pinata(metadata)

        batch_id_hash = Web3.keccak(text=batch_req.batchId)
        harvest_timestamp = int(datetime.utcnow().timestamp())
        
        tx = contract.functions.createBatch(
            batch_id_hash,
            batch_req.quantityGrams,
            harvest_timestamp,
            cid,
            metadata_bytes32
        ).build_transaction({
            'from': account.address,
            'nonce': w3.eth.get_transaction_count(account.address),
            'gas': 500000,
            'gasPrice': w3.eth.gas_price
        })

        signed_tx = w3.eth.account.sign_transaction(tx, private_key=PRIVATE_KEY)
        tx_hash = w3.eth.send_raw_transaction(signed_tx.raw_transaction)

        return {
            "status": "success",
            "message": "Batch uploaded to IPFS and committed to Polygon!",
            "ipfs_cid": cid,
            "ipfs_url": f"https://gateway.pinata.cloud/ipfs/{cid}",
            "transaction_hash": tx_hash.hex()
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
