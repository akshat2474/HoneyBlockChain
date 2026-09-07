import { Router } from 'express';
import { blockchainService } from '../services/blockchain.service';

export const verifyRoutes = Router();

verifyRoutes.get('/verify/:batchId', async (req, res, next) => {
  try {
    const batch = await blockchainService.getBatch(req.params.batchId);
    res.json({ success: true, batch });
  } catch (err) {
    next(err);
  }
});
