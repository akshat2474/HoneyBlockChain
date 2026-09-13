"""Pydantic schema for the public consumer verification response."""
from __future__ import annotations

from typing import Optional

from pydantic import BaseModel


class BlockchainProof(BaseModel):
    contract_address: str
    transaction_hash: Optional[str]
    block_explorer_url: Optional[str]
    batch_hash_on_chain: Optional[str]
    metadata_cid: Optional[str]
    metadata_hash_on_chain: Optional[str]
    lab_verified: bool
    recalled: bool


class IpfsProof(BaseModel):
    cid: Optional[str]
    gateway_url: Optional[str]
    hash_matches: Optional[bool]   # True if recomputed hash == on-chain hash


class VerifyResponse(BaseModel):
    batch_code: str
    status: str
    beekeeper_name: Optional[str]
    region: Optional[str]
    harvest_date: Optional[str]
    quantity_g: Optional[int]
    honey_type: Optional[str]
    blockchain: BlockchainProof
    ipfs: IpfsProof
    scan_count: int
    duplicate_warning: bool
