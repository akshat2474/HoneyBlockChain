import axios from 'axios';
import { config } from '../config';
import { logger } from '../utils/logger';

class WhatsAppClient {
  private get baseUrl() {
    return `https://graph.facebook.com/${config.WHATSAPP_API_VERSION}/${config.WHATSAPP_PHONE_NUMBER_ID}/messages`;
  }

  private get headers() {
    return {
      Authorization: `Bearer ${config.WHATSAPP_ACCESS_TOKEN}`,
      'Content-Type': 'application/json',
    };
  }

  async sendText(to: string, text: string) {
    try {
      await axios.post(this.baseUrl, {
        messaging_product: 'whatsapp',
        to,
        type: 'text',
        text: { body: text },
      }, { headers: this.headers });
    } catch (err: any) {
      logger.error(err?.response?.data || err, 'Error sending WA text');
    }
  }

  async sendButtons(to: string, bodyText: string, buttons: any[]) {
    try {
      await axios.post(this.baseUrl, {
        messaging_product: 'whatsapp',
        to,
        type: 'interactive',
        interactive: {
          type: 'button',
          body: { text: bodyText },
          action: { buttons }
        },
      }, { headers: this.headers });
    } catch (err: any) {
      logger.error(err?.response?.data || err, 'Error sending WA buttons');
    }
  }

  async sendList(to: string, bodyText: string, sections: any[]) {
    try {
      await axios.post(this.baseUrl, {
        messaging_product: 'whatsapp',
        to,
        type: 'interactive',
        interactive: {
          type: 'list',
          body: { text: bodyText },
          action: { button: 'Choose', sections }
        },
      }, { headers: this.headers });
    } catch (err: any) {
      logger.error(err?.response?.data || err, 'Error sending WA list');
    }
  }

  async markAsRead(messageId: string) {
    try {
      await axios.post(this.baseUrl, {
        messaging_product: 'whatsapp',
        status: 'read',
        message_id: messageId,
      }, { headers: this.headers });
    } catch (err: any) {
      logger.error(err?.response?.data || err, 'Error marking WA msg as read');
    }
  }
}

export const whatsappClient = new WhatsAppClient();
