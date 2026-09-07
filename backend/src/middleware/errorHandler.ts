import { Request, Response, NextFunction } from 'express';
import { logger } from '../utils/logger';
import { config } from '../config';

export function errorHandler(err: Error, req: Request, res: Response, _next: NextFunction) {
  logger.error({ err, method: req.method, url: req.url }, 'Unhandled error');

  const statusCode = 'statusCode' in err ? (err as any).statusCode : 500;
  const message = config.NODE_ENV === 'production' ? 'Internal Server Error' : err.message;

  res.status(statusCode).json({
    status: 'error',
    message,
    ...(config.NODE_ENV !== 'production' && { stack: err.stack }),
  });
}
