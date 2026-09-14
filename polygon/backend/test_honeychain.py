import requests
import uuid

BASE_URL = "https://honey-block-chain.vercel.app"

def print_header(title):
    print(f"\n{'='*50}\n{title}\n{'='*50}")

def random_string(prefix):
    """Generates a random string to ensure unique names/codes across test runs."""
    return f"{prefix}-{str(uuid.uuid4())[:6]}"

def main():
    print_header("HoneyChain Live API Tester")
    print(f"Targeting: {BASE_URL}")
    print("This script simulates the complete supply chain lifecycle.")

    # ---------------------------------------------------------
    # 1. Register Actors
    # ---------------------------------------------------------
    print("\n[1/5] Registering Supply Chain Actors...")
    
    # We use a dummy valid Polygon address for all test actors
    dummy_wallet = "0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB"
    
    bk_name = random_string("Beekeeper")
    lab_name = random_string("Lab")
    mfg_name = random_string("Processor")
    admin_name = random_string("Admin")

    bk_user = requests.post(f"{BASE_URL}/auth/register", json={"name": bk_name, "role": "beekeeper", "password": "pass", "region": "Reg", "wallet_address": dummy_wallet}).json()
    lab_user = requests.post(f"{BASE_URL}/auth/register", json={"name": lab_name, "role": "lab", "password": "pass", "region": "Reg", "wallet_address": dummy_wallet}).json()
    mfg_user = requests.post(f"{BASE_URL}/auth/register", json={"name": mfg_name, "role": "processor", "password": "pass", "region": "Reg", "wallet_address": dummy_wallet}).json()
    adm_user = requests.post(f"{BASE_URL}/auth/register", json={"name": admin_name, "role": "admin", "password": "pass", "region": "Reg", "wallet_address": dummy_wallet}).json()

    print(f"  Created Beekeeper: {bk_name}")
    print(f"  Created Lab: {lab_name}")
    print(f"  Created Processor: {mfg_name}")
    
    # Login to get JWT tokens
    t_bk = requests.post(f"{BASE_URL}/auth/login", json={"name": bk_name, "password": "pass"}).json()["access_token"]
    t_lab = requests.post(f"{BASE_URL}/auth/login", json={"name": lab_name, "password": "pass"}).json()["access_token"]
    t_mfg = requests.post(f"{BASE_URL}/auth/login", json={"name": mfg_name, "password": "pass"}).json()["access_token"]
    t_admin = requests.post(f"{BASE_URL}/auth/login", json={"name": admin_name, "password": "pass"}).json()["access_token"]

    # ---------------------------------------------------------
    # 2. Beekeeper: Create Hive & Harvest
    # ---------------------------------------------------------
    print("\n[2/5] Creating Hive and recording Harvest...")
    
    hive = requests.post(
        f"{BASE_URL}/hive/", 
        headers={"Authorization": f"Bearer {t_bk}"}, 
        json={"beekeeper_id": bk_user["id"], "device_id": "ESP32-TEST", "region_public": "California"}
    ).json()
    
    harvest = requests.post(
        f"{BASE_URL}/harvest/", 
        headers={"Authorization": f"Bearer {t_bk}"}, 
        json={"hive_id": hive["id"], "harvest_date": "2026-09-13T08:00:00", "quantity_g": 1000, "floral_source": "Wildflower"}
    ).json()
    
    print(f"  Harvest ID recorded: {harvest['id']}")

    # ---------------------------------------------------------
    # 3. Beekeeper: Mint Batch to Blockchain
    # ---------------------------------------------------------
    print("\n[3/5] Minting Batch to Polygon Amoy & pinning to IPFS...")
    
    batch_code = random_string("BATCH")
    batch = requests.post(
        f"{BASE_URL}/batch/", 
        headers={"Authorization": f"Bearer {t_bk}"}, 
        json={"batch_code": batch_code, "harvest_id": harvest["id"], "honey_type": "Raw Organic", "region": "California"}
    ).json()
    
    batch_id = batch["id"]
    print(f"  Batch Created!")
    print(f"     Polygon Tx: https://amoy.polygonscan.com/tx/{batch.get('create_tx_hash')}")
    print(f"     IPFS Data:  https://gateway.pinata.cloud/ipfs/{batch.get('metadata_cid')}")

    # ---------------------------------------------------------
    # 4. Lab: Verify Purity
    # ---------------------------------------------------------
    print("\n[4/5] Lab verifying purity on-chain...")
    
    lab_res = requests.post(
        f"{BASE_URL}/lab-verification", 
        headers={"Authorization": f"Bearer {t_lab}"}, 
        json={
            "batch_id": batch_id, 
            "lab_name": "Pure Labs LLC", 
            "certificate_hash": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855", 
            "certificate_cid": "QmTestCertificateCID123"
        }
    ).json()
    
    print(f"  Lab Verified!")
    print(f"     Polygon Tx: https://amoy.polygonscan.com/tx/{lab_res.get('tx_hash')}")

    # ---------------------------------------------------------
    # 5. Admin: Recall Batch
    # ---------------------------------------------------------
    print("\n[5/5] Admin recalling contaminated batch on-chain...")
    
    recall_res = requests.post(
        f"{BASE_URL}/batch/{batch_id}/recall", 
        headers={"Authorization": f"Bearer {t_admin}"}, 
        json={"reason": "Contamination Detected"}
    ).json()
    
    print(f"  Batch Recalled!")
    print(f"     Polygon Tx: https://amoy.polygonscan.com/tx/{recall_res.get('tx_hash')}")

    print_header("Lifecycle Test Complete!")
    print(f"To see the public consumer verification endpoint for this batch, visit:\n{BASE_URL}/verify/{batch_code}?n=TOKEN&sig=SIGNATURE")

if __name__ == "__main__":
    main()
