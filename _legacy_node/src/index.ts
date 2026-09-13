import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import { pinoHttp } from 'pino-http';
import rateLimit from 'express-rate-limit';
import { config } from './config';
import { logger } from './utils/logger';
import { errorHandler } from './middleware/errorHandler';
import { batchRoutes } from './routes/batch.routes';
import { healthRoutes } from './routes/health.routes';
import { verifyRoutes } from './routes/verify.routes';
import { webhookRoutes } from './whatsapp/webhook.routes';

const app = express();

// Security
app.use(helmet());
app.use(cors());

// WhatsApp webhook needs raw body for HMAC verification
app.use('/webhook', express.raw({ type: 'application/json' }));

// JSON parsing for other routes
app.use(express.json());

// Logging
app.use(pinoHttp({ logger }));

// Trust proxy (behind cloudflare tunnel)
app.set('trust proxy', 1);

// Rate limiting (skip webhook — Meta sends many requests per message)
app.use('/api', rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 200,
  standardHeaders: true,
  legacyHeaders: false,
}));

// Routes
app.use('/api', healthRoutes);
app.use('/api', batchRoutes);
app.use('/api', verifyRoutes);
app.use('/', webhookRoutes);

// Error handling
app.use(errorHandler);

app.listen(config.PORT, () => {
  logger.info(`🚀 HoneyBlockChain backend running on port ${config.PORT}`);
  logger.info(`📡 WhatsApp webhook: http://localhost:${config.PORT}/webhook/whatsapp`);
  logger.info(`🔗 Health check: http://localhost:${config.PORT}/api/health`);
});

export default app;
