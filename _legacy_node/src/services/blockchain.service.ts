import { ethers } from 'ethers';
import { config } from '../config';
import { logger } from '../utils/logger';
import fs from 'fs';
import path from 'path';

class BlockchainService {
  private provider: ethers.JsonRpcProvider | null = null;
  private wallet: ethers.Wallet | null = null;
  private contract: ethers.Contract | null = null;
  private isConnected = false;

  constructor() {
    this.init();
  }

  private init() {
    try {
      if (!config.AMOY_RPC_URL || !config.PRIVATE_KEY || !config.CONTRACT_ADDRESS) {
        logger.warn('Blockchain config missing. Running in mock mode.');
        return;
      }

      this.provider = new ethers.JsonRpcProvider(config.AMOY_RPC_URL);
      this.wallet = new ethers.Wallet(config.PRIVATE_KEY, this.provider);

      const abiPath = path.resolve(__dirname, '../../../blockchain/artifacts/contracts/HoneyChain.sol/HoneyChain.json');
      if (fs.existsSync(abiPath)) {
        const artifact = JSON.parse(fs.readFileSync(abiPath, 'utf8'));
        this.contract = new ethers.Contract(config.CONTRACT_ADDRESS, artifact.abi, this.wallet);
        this.isConnected = true;
        logger.info('Connected to blockchain');
      } else {
        logger.warn('Contract ABI not found. Running in mock mode.');
      }
    } catch (err) {
      logger.error({ err }, 'Failed to initialize blockchain service');
    }
  }

  async createBatch(batchIdHash: string, quantityGrams: number, harvestTimestamp: number, metadataCID: string, metadataHash: string) {
    if (!this.isConnected || !this.contract) {
      logger.info('Mock: createBatch called');
      return 'mock-tx-hash';
    }
    const tx = await this.contract.createBatch(batchIdHash, quantityGrams, harvestTimestamp, metadataCID, metadataHash);
    await tx.wait();
    return tx.hash;
  }

  async verifyLab(batchIdHash: string, labReportHash: string, metadataCID: string, metadataHash: string) {
    if (!this.isConnected || !this.contract) {
      logger.info('Mock: verifyLab called');
      return 'mock-tx-hash';
    }
    const tx = await this.contract.verifyLab(batchIdHash, labReportHash, metadataCID, metadataHash);
    await tx.wait();
    return tx.hash;
  }

  async transferCustody(batchIdHash: string, to: string, nextStatus: number) {
    if (!this.isConnected || !this.contract) {
      logger.info('Mock: transferCustody called');
      return 'mock-tx-hash';
    }
    const tx = await this.contract.transferCustody(batchIdHash, to, nextStatus);
    await tx.wait();
    return tx.hash;
  }

  async recallBatch(batchIdHash: string, reasonCID: string) {
    if (!this.isConnected || !this.contract) {
      logger.info('Mock: recallBatch called');
      return 'mock-tx-hash';
    }
    const tx = await this.contract.recallBatch(batchIdHash, reasonCID);
    await tx.wait();
    return tx.hash;
  }

  async getBatch(batchIdHash: string) {
    if (!this.isConnected || !this.contract) {
      logger.info('Mock: getBatch called');
      return { status: 0, quantityGrams: 0, beekeeper: ethers.ZeroAddress };
    }
    return await this.contract.getBatch(batchIdHash);
  }
}

export const blockchainService = new BlockchainService();
