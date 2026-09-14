import os
import json
import time
from web3 import Web3
from dotenv import load_dotenv
from eth_account import Account

load_dotenv()

RPC_URL = os.getenv("AMOY_RPC_URL", "https://rpc-amoy.polygon.technology")
PRIVATE_KEY = os.getenv("PRIVATE_KEY")  # Must be DEFAULT_ADMIN_ROLE holder
CONTRACT_ADDRESS = os.getenv("CONTRACT_ADDRESS", "0x5BFA55A855Da3687d0f9CDA33ae3f64f7a3629aB")

if not PRIVATE_KEY:
    raise ValueError("PRIVATE_KEY not found in environment variables.")

w3 = Web3(Web3.HTTPProvider(RPC_URL))
admin_account = Account.from_key(PRIVATE_KEY)

# Use the ABI from the blockchain directory as specified or fallback to the app/services/abi.json
abi_path = os.path.join(os.path.dirname(__file__), "app", "services", "abi.json")
with open(abi_path, "r") as f:
    contract_abi = json.load(f)["abi"]

contract = w3.eth.contract(address=CONTRACT_ADDRESS, abi=contract_abi)

ROLES = [
    "BEEKEEPER_ROLE",
    "LAB_ROLE",
    "PROCESSOR_ROLE",
    "DISTRIBUTOR_ROLE",
    "RETAILER_ROLE"
]

relayer_address = admin_account.address  # We grant roles to the relayer itself

print(f"Checking and granting roles for relayer address: {relayer_address}")
print("-" * 50)

for role_name in ROLES:
    role_hash = w3.keccak(text=role_name)
    has_role = contract.functions.hasRole(role_hash, relayer_address).call()
    
    if has_role:
        print(f"[{role_name}] Wallet already possesses this role.")
    else:
        print(f"[{role_name}] Granting role to {relayer_address}...")
        tx = contract.functions.grantRole(role_hash, relayer_address).build_transaction({
            'from': admin_account.address,
            'nonce': w3.eth.get_transaction_count(admin_account.address),
            'gas': 120000,
            'gasPrice': w3.eth.gas_price
        })
        signed_tx = w3.eth.account.sign_transaction(tx, private_key=PRIVATE_KEY)
        tx_hash = w3.eth.send_raw_transaction(signed_tx.raw_transaction)
        print(f"[{role_name}] Tx submitted! Hash: {tx_hash.hex()}")
        
        # Wait for receipt
        receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
        print(f"[{role_name}] Confirmed in block: {receipt.blockNumber}")
        time.sleep(2) # avoid rate limits
        
print("-" * 50)
print("All roles are successfully set on Polygon Amoy!")
