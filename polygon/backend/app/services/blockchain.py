"""Blockchain service — all web3.py interactions with the HoneyChain contract."""
from __future__ import annotations

import hashlib
import json
import os
from typing import Any, Dict, Optional

from eth_account import Account
from web3 import Web3

from dotenv import load_dotenv

load_dotenv()

# ---------- Setup ----------

_RPC_URL = os.getenv("AMOY_RPC_URL", "")
_PRIVATE_KEY = os.getenv("PRIVATE_KEY", "")
_CONTRACT_ADDRESS = os.getenv("CONTRACT_ADDRESS", "")

w3 = Web3(Web3.HTTPProvider(_RPC_URL))
account = Account.from_key(_PRIVATE_KEY) if _PRIVATE_KEY else None

_ABI_PATH = os.path.abspath(
    os.path.join(
        os.path.dirname(__file__),
        "../../../blockchain/artifacts/contracts/HoneyChain.sol/HoneyChain.json",
    )
)

contract = None
try:
    with open(_ABI_PATH) as f:
        contract_abi = json.load(f)["abi"]
    contract = w3.eth.contract(address=_CONTRACT_ADDRESS, abi=contract_abi)
except Exception as exc:
    print(f"[blockchain] Warning: could not load ABI — {exc}")


# ---------- Helpers ----------

def _require_contract():
    if contract is None:
        raise RuntimeError("Smart contract ABI not loaded. Run `npx hardhat compile` first.")


def _build_and_send(func_call) -> str:
    """Estimate gas, build, sign, and broadcast a transaction. Returns tx hash hex."""
    gas = func_call.estimate_gas({"from": account.address})
    tx = func_call.build_transaction(
        {
            "from": account.address,
            "nonce": w3.eth.get_transaction_count(account.address),
            "gas": int(gas * 1.2),
            "gasPrice": w3.eth.gas_price,
        }
    )
    signed = w3.eth.account.sign_transaction(tx, private_key=_PRIVATE_KEY)
    tx_hash = w3.eth.send_raw_transaction(signed.raw_transaction)
    return tx_hash.hex()


def batch_id_hash(batch_code: str) -> bytes:
    """keccak256 of the batch code string — matches the on-chain key."""
    return Web3.keccak(text=batch_code)


def metadata_bytes32(metadata_json_str: str) -> bytes:
    """SHA-256 of a canonical JSON string, returned as 32 bytes for Solidity bytes32."""
    digest = hashlib.sha256(metadata_json_str.encode()).hexdigest()
    return Web3.to_bytes(hexstr=digest)


# ---------- Public API ----------

def create_batch_tx(
    batch_code: str,
    quantity_grams: int,
    harvest_timestamp: int,
    metadata_cid: str,
    metadata_json_str: str,
) -> str:
    _require_contract()
    bid_hash = batch_id_hash(batch_code)
    m_bytes = metadata_bytes32(metadata_json_str)
    func = contract.functions.createBatch(
        bid_hash, quantity_grams, harvest_timestamp, metadata_cid, m_bytes
    )
    return _build_and_send(func)


def verify_lab_tx(
    batch_code: str,
    lab_report_hash_hex: str,
    metadata_cid: str,
    metadata_json_str: str,
) -> str:
    _require_contract()
    bid_hash = batch_id_hash(batch_code)
    lab_bytes = Web3.to_bytes(hexstr=lab_report_hash_hex)
    m_bytes = metadata_bytes32(metadata_json_str)
    func = contract.functions.verifyLab(bid_hash, lab_bytes, metadata_cid, m_bytes)
    return _build_and_send(func)


def transfer_custody_tx(
    batch_code: str,
    to_address: str,
    next_status_index: int,
) -> str:
    _require_contract()
    bid_hash = batch_id_hash(batch_code)
    func = contract.functions.transferCustody(bid_hash, to_address, next_status_index)
    return _build_and_send(func)


def recall_batch_tx(batch_code: str, reason_cid: str) -> str:
    _require_contract()
    bid_hash = batch_id_hash(batch_code)
    func = contract.functions.recallBatch(bid_hash, reason_cid)
    return _build_and_send(func)


def get_batch_on_chain(batch_code: str) -> Optional[Dict[str, Any]]:
    """Read batch data from the contract (free, no gas). Returns None if not found."""
    _require_contract()
    try:
        bid_hash = batch_id_hash(batch_code)
        result = contract.functions.getBatch(bid_hash).call()
        # Result is a tuple matching the HoneyBatch struct
        return {
            "batchIdHash": result[0].hex(),
            "beekeeper": result[1],
            "currentCustodian": result[2],
            "harvestTimestamp": result[3],
            "createdAt": result[4],
            "quantityGrams": result[5],
            "status": result[6],
            "metadataCID": result[7],
            "metadataHash": result[8].hex(),
            "labReportHash": result[9].hex(),
            "labVerified": result[10],
            "recalled": result[11],
        }
    except Exception:
        return None
