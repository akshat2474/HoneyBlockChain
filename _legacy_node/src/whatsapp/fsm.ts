import { redisService } from '../services/redis.service';
import { ConversationState } from './states';

export class FSM {
  static async getState(waId: string) {
    const session = await redisService.getSession(waId);
    if (!session) {
      return { state: ConversationState.IDLE, data: {} };
    }
    return session;
  }

  static async setState(waId: string, state: ConversationState, data: any = {}) {
    await redisService.setSession(waId, state, data);
  }

  static async clearState(waId: string) {
    await redisService.deleteSession(waId);
  }
}
