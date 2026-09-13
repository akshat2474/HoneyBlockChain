import os
import json
from web3 import Web3
from dotenv import load_dotenv
from eth_account import Account

load_dotenv()

RPC_URL = os.getenv("AMOY_RPC_URL")
PRIVATE_KEY = os.getenv("PRIVATE_KEY")
CONTRACT_ADDRESS = os.getenv("CONTRACT_ADDRESS")

w3 = Web3(Web3.HTTPProvider(RPC_URL))
account = Account.from_key(PRIVATE_KEY)

abi_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../blockchain/artifacts/contracts/HoneyChain.sol/HoneyChain.json'))
with open(abi_path, 'r') as file:
    contract_abi = json.load(file)['abi']

contract = w3.eth.contract(address=CONTRACT_ADDRESS, abi=contract_abi)

BEEKEEPER_ROLE = w3.keccak(text="BEEKEEPER_ROLE")

print("Checking if you have the BEEKEEPER_ROLE...")
has_role = contract.functions.hasRole(BEEKEEPER_ROLE, account.address).call()

if has_role:
    print("You already have the role!")
else:
    print("You don't have the role! Granting it now as the Admin...")
    tx = contract.functions.grantRole(BEEKEEPER_ROLE, account.address).build_transaction({
        'from': account.address,
        'nonce': w3.eth.get_transaction_count(account.address),
        'gas': 100000,
        'gasPrice': w3.eth.gas_price
    })
    signed_tx = w3.eth.account.sign_transaction(tx, private_key=PRIVATE_KEY)
    tx_hash = w3.eth.send_raw_transaction(signed_tx.raw_transaction)
    print(f"Role granted! Transaction hash: {tx_hash.hex()}")
    print("Wait ~5 seconds for it to confirm, then try your FastAPI request again!")
