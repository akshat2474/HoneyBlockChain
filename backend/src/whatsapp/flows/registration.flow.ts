import { whatsappClient } from '../client';
import { FSM } from '../fsm';
import { ConversationState } from '../states';
import { logger } from '../../utils/logger';

// Validation helpers
function validateName(name: string): string | null {
  if (name.length < 2) return '❌ Name is too short. Please enter at least 2 characters.';
  if (name.length > 100) return '❌ Name is too long. Please keep it under 100 characters.';
  if (/\d/.test(name)) return '❌ Name should not contain numbers. Please enter your full name using letters only.';
  if (/[^a-zA-Z\s.\-']/.test(name)) return '❌ Name contains invalid characters. Use only letters, spaces, dots, or hyphens.';
  return null;
}

function validatePhone(phone: string): string | null {
  const cleaned = phone.replace(/[\s\-+()]/g, '');
  if (!/^\d{10,13}$/.test(cleaned)) return '❌ Invalid phone number. Please enter a 10-digit Indian mobile number (e.g., 9876543210).';
  if (cleaned.length === 10 && !/^[6-9]/.test(cleaned)) return '❌ Indian mobile numbers start with 6, 7, 8, or 9.';
  return null;
}

function validateEmail(email: string): string | null {
  if (email.toLowerCase() === 'skip') return null;
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) return '❌ Invalid email format. Please enter a valid email (e.g., name@example.com) or type SKIP.';
  return null;
}

function validateRegion(region: string): string | null {
  if (region.length < 2) return '❌ Region name too short. Enter your district/state (e.g., Dehradun, Uttarakhand).';
  if (/\d/.test(region)) return '❌ Region should not contain numbers.';
  return null;
}

export async function handleRegistration(waId: string, message: any, state: string, data: any) {
  const text = message.text?.body?.trim();
  
  // Allow cancel at any step
  if (text?.toLowerCase() === 'cancel') {
    await FSM.clearState(waId);
    await whatsappClient.sendText(waId, '❌ Registration cancelled. Send *hi* to return to the menu.');
    return;
  }

  if (!text) {
    await whatsappClient.sendText(waId, '⚠️ Please reply with text. Send *cancel* to exit registration.');
    return;
  }

  switch (state) {
    case ConversationState.REGISTRATION_NAME: {
      const error = validateName(text);
      if (error) {
        await whatsappClient.sendText(waId, `${error}\n\n*Step 1/5:* Please enter your full name again:`);
        return;
      }
      data.name = text;
      await FSM.setState(waId, ConversationState.REGISTRATION_PHONE, data);
      await whatsappClient.sendText(waId, `✅ Name: *${text}*\n\n*Step 2/5:* Enter your 10-digit mobile number:\n(e.g., 9876543210)`);
      break;
    }

    case ConversationState.REGISTRATION_PHONE: {
      const error = validatePhone(text);
      if (error) {
        await whatsappClient.sendText(waId, `${error}\n\n*Step 2/5:* Please enter your mobile number again:`);
        return;
      }
      const cleaned = text.replace(/[\s\-+()]/g, '');
      data.phone = cleaned.length === 10 ? `+91${cleaned}` : `+${cleaned}`;
      await FSM.setState(waId, ConversationState.REGISTRATION_EMAIL, data);
      await whatsappClient.sendText(waId, `✅ Phone: *${data.phone}*\n\n*Step 3/5:* Enter your email address:\n(Type *SKIP* if you don't have one)`);
      break;
    }

    case ConversationState.REGISTRATION_EMAIL: {
      const error = validateEmail(text);
      if (error) {
        await whatsappClient.sendText(waId, `${error}\n\n*Step 3/5:* Please enter a valid email or type SKIP:`);
        return;
      }
      data.email = text.toLowerCase() === 'skip' ? null : text.toLowerCase();
      await FSM.setState(waId, ConversationState.REGISTRATION_REGION, data);
      await whatsappClient.sendText(waId, `✅ Email: *${data.email || 'Skipped'}*\n\n*Step 4/5:* Enter your region/district:\n(e.g., Dehradun, Uttarakhand)`);
      break;
    }

    case ConversationState.REGISTRATION_REGION: {
      const error = validateRegion(text);
      if (error) {
        await whatsappClient.sendText(waId, `${error}\n\n*Step 4/5:* Please enter your region again:`);
        return;
      }
      data.region = text;
      await FSM.setState(waId, ConversationState.REGISTRATION_KVIC, data);
      await whatsappClient.sendText(waId, `✅ Region: *${text}*\n\n*Step 5/5:* Enter your KVIC Registration ID:\n(Type *SKIP* if you don't have one yet)`);
      break;
    }

    case ConversationState.REGISTRATION_KVIC: {
      data.kvicId = text.toLowerCase() === 'skip' ? null : text.toUpperCase();
      await FSM.setState(waId, ConversationState.REGISTRATION_CONFIRM, data);

      const summary = `📋 *Registration Summary*\n\n`
        + `👤 Name: *${data.name}*\n`
        + `📱 Phone: *${data.phone}*\n`
        + `📧 Email: *${data.email || 'Not provided'}*\n`
        + `📍 Region: *${data.region}*\n`
        + `🏛️ KVIC ID: *${data.kvicId || 'Not provided'}*\n\n`
        + `Is this correct?`;

      await whatsappClient.sendButtons(waId, summary, [
        { type: 'reply', reply: { id: 'reg_confirm_yes', title: '✅ Confirm' } },
        { type: 'reply', reply: { id: 'reg_confirm_no', title: '❌ Start Over' } },
        { type: 'reply', reply: { id: 'reg_confirm_cancel', title: '🚫 Cancel' } },
      ]);
      break;
    }

    case ConversationState.REGISTRATION_CONFIRM: {
      const buttonId = message.interactive?.button_reply?.id || text.toLowerCase();

      if (buttonId === 'reg_confirm_yes' || buttonId === 'yes' || buttonId === 'y') {
        // Save to database (hardcoded success for now)
        logger.info({ data }, '✅ Beekeeper registered');
        
        await whatsappClient.sendText(waId,
          `🎉 *Registration Successful!*\n\n`
          + `Welcome to HoneyBlockChain, *${data.name}*!\n\n`
          + `Your beekeeper profile has been created. You can now:\n`
          + `• Track your honey batches on blockchain\n`
          + `• Get AI-powered disease detection\n`
          + `• Access market prices & health reports\n\n`
          + `🔗 Wallet address will be assigned shortly.\n\n`
          + `Send *hi* to return to the menu.`
        );
        await FSM.clearState(waId);
      } else if (buttonId === 'reg_confirm_no' || buttonId === 'no' || buttonId === 'n') {
        await FSM.setState(waId, ConversationState.REGISTRATION_NAME, {});
        await whatsappClient.sendText(waId, '🔄 Let\'s start over.\n\n*Step 1/5:* What is your full name?');
      } else {
        await FSM.clearState(waId);
        await whatsappClient.sendText(waId, '❌ Registration cancelled. Send *hi* to return to the menu.');
      }
      break;
    }
  }
}
