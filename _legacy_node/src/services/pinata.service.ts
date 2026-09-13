import axios from 'axios';
import { config } from '../config';
import { logger } from '../utils/logger';

export const pinataService = {
  async uploadJSON(metadata: any): Promise<string> {
    try {
      if (!config.PINATA_JWT) {
        logger.warn('PINATA_JWT not found, returning dummy CID');
        return 'QmDummyCID...';
      }
      const response = await axios.post(
        'https://api.pinata.cloud/pinning/pinJSONToIPFS',
        { pinataContent: metadata },
        {
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${config.PINATA_JWT}`,
          },
        }
      );
      return response.data.IpfsHash;
    } catch (error) {
      logger.error({ error }, 'Pinata upload failed');
      throw new Error('Failed to upload metadata to IPFS');
    }
  },
};
