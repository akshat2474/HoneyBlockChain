# Implementation Plan: Transfer and Custody Flow

## Overview
Implement the 'Transfer and Custody' flow for the WhatsApp bot, allowing users to transfer ownership of a honey batch to another user.

## Requirements
1. **Routing**:
    - Add "Transfer Custody" button to the Market menu.
    - Route `TRANSFER_` states to `handle_transfer`.
2. **Flow Logic**:
    - `TRANSFER_BATCH_ID`: Prompt for Batch ID $\rightarrow$ Validate existence and ownership $\rightarrow$ `TRANSFER_BUYER_ID`.
    - `TRANSFER_BUYER_ID`: Prompt for Buyer's WhatsApp ID $\rightarrow$ `TRANSFER_CONFIRM`.
    - `TRANSFER_CONFIRM`: Summary $\rightarrow$ Confirm 'Yes'/'cancel' $\rightarrow$ Update DB $\rightarrow$ `MAIN_MENU`.
3. **Consistency**:
    - Use plain English (no `i18n`).
    - Use `batch_id_hash`.
    - Handle DB errors gracefully.

## Implementation Details

### 1. Routing & Menu Entry
- **File**: `whatsapp_bot/whatsapp/flows/interactive_menus.py`
    - In `handle_interactive_menus`, under `ConversationState.MAIN_MENU`, inside the `menu_market_schemes` handler, add:
      `{"type": "reply", "reply": {"id": "market_transfer", "title": "Transfer Custody"}}`
    - Under `ConversationState.MENU_MARKET`, add handling for `market_transfer`:
      - Prompt: "Please enter the Batch ID you wish to transfer (e.g., BATCH-123):"
      - Action: `await redis_service.set_session(wa_id, ConversationState.TRANSFER_BATCH_ID, data)`

- **File**: `whatsapp_bot/whatsapp/handler.py`
    - In `handle_message`, update routing logic (around line 127) to route `TRANSFER_` states:
      ```python
      if state.startswith("REGISTRATION_"):
          await handle_registration(wa_id, message, state, data, current_lang)
      elif state.startswith("TRANSFER_"):
          from whatsapp.flows.transfer import handle_transfer
          await handle_transfer(wa_id, message, state, data, current_lang)
      elif state in [ConversationState.MAIN_MENU, ...]:
          # ... existing interactive_menus routing
      ```

### 2. Flow Logic Implementation
- **File**: `whatsapp_bot/whatsapp/flows/transfer.py`
    - Remove `from whatsapp.i18n import t`.
    - Rewrite `handle_transfer` with the following state machine:

#### State: `TRANSFER_BATCH_ID`
- **Input**: `text = data.get("english_text", "").strip()`
- **Validation**:
    - Must start with "BATCH-".
    - Query `HoneyBatch` where `batch_id_hash == text`.
    - Ensure `batch.current_custodian == wa_id`.
- **Success**:
    - Save `data["batch_id"] = text`.
    - Prompt: "Batch found! Now, please enter the WhatsApp ID of the buyer (e.g., 91XXXXXXXXXX):"
    - Set state: `ConversationState.TRANSFER_BUYER_ID`.
- **Failure**:
    - Send error ("Batch not found" or "You are not the current custodian").
    - Stay in `TRANSFER_BATCH_ID`.

#### State: `TRANSFER_BUYER_ID`
- **Input**: `text = data.get("english_text", "").strip()`
- **Validation**: Non-empty string.
- **Success**:
    - Save `data["buyer_id"] = text`.
    - Prompt: `f"Confirm Transfer:\n\nBatch: {data['batch_id']}\nBuyer: {text}\n\nReply 'Yes' to confirm or 'cancel' to stop."`
    - Set state: `ConversationState.TRANSFER_CONFIRM`.
- **Failure**:
    - Prompt for a valid ID.

#### State: `TRANSFER_CONFIRM`
- **Input**: `text = data.get("english_text", "").strip().lower()`
- **Logic**:
    - If `text == "yes"`:
        - DB Update: `batch = db.query(HoneyBatch).filter(HoneyBatch.batch_id_hash == data["batch_id"]).first()`, `batch.current_custodian = data["buyer_id"]`, `db.commit()`.
        - Reply: "✅ Transfer Successful! The batch has been moved to the buyer's custody."
        - Set state: `ConversationState.MAIN_MENU`.
    - If `text == "cancel"`:
        - Reply: "❌ Transfer cancelled."
        - Set state: `ConversationState.MAIN_MENU`.
    - Else:
        - Reply: "Please reply 'Yes' to confirm or 'cancel' to abort."

### 3. Database & Error Handling
- Use `SessionLocal()` for DB transactions.
- Wrap DB calls in `try...except...finally` to ensure `db.close()` is called.
- If a DB error occurs, notify the user: "⚠️ A system error occurred while updating the record. Please try again later."

## Verification Plan
1. **Menu Entry**: Market $\rightarrow$ Transfer Custody $\rightarrow$ Check if it asks for Batch ID.
2. **Validation Tests**:
    - Input invalid Batch ID format $\rightarrow$ Error.
    - Input non-existent Batch ID $\rightarrow$ Error.
    - Input Batch ID owned by another user $\rightarrow$ "You do not own this batch" Error.
3. **Happy Path**:
    - Valid Batch ID $\rightarrow$ Valid Buyer ID $\rightarrow$ "Yes" $\rightarrow$ Success message $\rightarrow$ Return to Main Menu.
    - Verify in DB that `current_custodian` has changed.
4. **Cancel Path**:
    - Start flow $\rightarrow$ type 'cancel' at any step $\rightarrow$ Return to Main Menu.
