import { Router } from 'express';
import { blockchainService } from '../services/blockchain.service';
import { pinataService } from '../services/pinata.service';
import { ethers } from 'ethers';

export const batchRoutes = Router();

batchRoutes.post('/batches', async (req, res, next) => {
  try {
    const { batchIdHash, quantityGrams, harvestTimestamp, metadata } = req.body;
    const cid = await pinataService.uploadJSON(metadata);
    const hash = ethers.keccak256(ethers.toUtf8Bytes(JSON.stringify(metadata)));
    
    const txHash = await blockchainService.createBatch(batchIdHash, quantityGrams, harvestTimestamp, cid, hash);
    res.json({ success: true, txHash, cid });
  } catch (err) {
    next(err);
  }
});

batchRoutes.get('/batches/:batchId', async (req, res, next) => {
  try {
    const batch = await blockchainService.getBatch(req.params.batchId);
    res.json({ success: true, batch });
  } catch (err) {
    next(err);
  }
});

batchRoutes.post('/batches/:batchId/verify-lab', async (req, res, next) => {
  try {
    const { labReportHash, metadataCID, metadataHash } = req.body;
    const txHash = await blockchainService.verifyLab(req.params.batchId, labReportHash, metadataCID, metadataHash);
    res.json({ success: true, txHash });
  } catch (err) {
    next(err);
  }
});

batchRoutes.post('/batches/:batchId/transfer', async (req, res, next) => {
  try {
    const { to, nextStatus } = req.body;
    const txHash = await blockchainService.transferCustody(req.params.batchId, to, nextStatus);
    res.json({ success: true, txHash });
  } catch (err) {
    next(err);
  }
});

batchRoutes.post('/batches/:batchId/recall', async (req, res, next) => {
  try {
    const { reasonCID } = req.body;
    const txHash = await blockchainService.recallBatch(req.params.batchId, reasonCID);
    res.json({ success: true, txHash });
  } catch (err) {
    next(err);
  }
});
