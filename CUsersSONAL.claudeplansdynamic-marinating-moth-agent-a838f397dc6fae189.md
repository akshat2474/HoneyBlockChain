# Implementation Plan: WhatsApp Bot Flow Improvements (Phase 1)

## Overview
The objective is to fix the harvest registration saving mechanism, implement a global command interceptor for navigation, and clean up the handler's architecture by extracting support and IoT logic into a dedicated module.

## Requirements
- Maintain Redis FSM pattern.
- Correct DB session management (open/commit/close).
- Dynamic response language using `current_lang`.
- Fix the missing link between `WhatsAppUser` and `Beekeeper`.

---

## Step-by-Step Implementation

### 1. Fix User-Beekeeper Linkage (Critical Pre-requisite)
The current registration flow creates a `Beekeeper` but does not link it to the `WhatsAppUser`. This must be fixed first so that harvest saving can find the `beekeeper_id`.

**File:** `whatsapp_bot/whatsapp/flows/registration.py`
- In the `ConversationState.REGISTRATION_PRACTICES` handler:
    - After `db.commit()` for the `Beekeeper` object (`bk`).
    - Fetch the `WhatsAppUser` record: `user = db.query(WhatsAppUser).filter(WhatsAppUser.wa_id == wa_id).first()`.
    - Update the link: `user.beekeeper_id = bk.id`.
    - Commit the change: `db.commit()`.

### 2. Fix Harvest Saving (Goal 1)
Currently, the harvest registration only sends a confirmation message but doesn't persist data to the database.

**File:** `whatsapp_bot/whatsapp/flows/interactive_menus.py`
- In the `ConversationState.HARVEST_WEIGHT` handler:
    - Import `SessionLocal`, `WhatsAppUser`, and `HoneyBatch`.
    - Use a `with` block or `try-finally` for `SessionLocal()`.
    - Retrieve the `WhatsAppUser` via `wa_id`.
    - Verify `user.beekeeper_id` is present. If not, notify the user that they must register first.
    - **Data Preparation:**
        - `batch_id_hash`: Generate using `uuid.uuid4().hex`.
        - `quantity_grams`: Convert `digits` (kg) to grams (`float(digits) * 1000`).
        - `honey_type`: Default to `'Multiflora'`.
        - `status`: Set to `'REGISTERED'`.
    - Create and save a `HoneyBatch` record associated with the `beekeeper_id`.
    - Commit and close the session.

### 3. Global Command System (Goal 2)
Implement an interceptor to allow users to navigate regardless of their current state in the FSM.

**File:** `whatsapp_bot/whatsapp/handler.py`
- Inside `handle_message`, after `current_lang` is determined and before routing to flows:
    - Check if `english_text.lower()` matches `'menu'`, `'cancel'`, or `'back'`.
    - **If 'menu':**
        - Update Redis state: `await redis_service.set_session(wa_id, ConversationState.MAIN_MENU, data)`.
        - Call `await handle_main_menu(wa_id, current_lang)`.
        - Return immediately to prevent flow routing.
    - **If 'cancel' or 'back':**
        - Implement similar logic to return to `MAIN_MENU` or handle specific flow reversals if applicable.

### 4. Architecture Cleanup (Goal 3)
Move the IoT mock and support logic out of the main handler to improve maintainability.

**New File:** `whatsapp_bot/whatsapp/flows/support.py`
- Implement `async def handle_iot_status(wa_id, lang)`:
    - Move the "IoT Hive Status" mock text and `send_text` call here.
- Implement `async def handle_support_query(wa_id, english_text, data, lang)`:
    - Move the LLM support query logic (including Gemini client call and Redis memory update) here.

**File:** `whatsapp_bot/whatsapp/handler.py`
- Remove the blocks of code for IoT and Support queries.
- Import the new functions from `.flows.support`.
- Update the routing logic to call these functions.

---

## Critical Files for Implementation
- `whatsapp_bot/models.py` (Reference for models)
- `whatsapp_bot/whatsapp/handler.py` (Global commands & cleanup)
- `whatsapp_bot/whatsapp/flows/interactive_menus.py` (Harvest saving)
- `whatsapp_bot/whatsapp/flows/registration.py` (User-Beekeeper linkage)
- `whatsapp_bot/whatsapp/flows/support.py` (New file for support logic)
EOF`
