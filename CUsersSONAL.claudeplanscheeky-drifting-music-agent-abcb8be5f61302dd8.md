# Implementation Plan: WhatsApp Bot Re-audit Fixes

This plan addresses 8 issues identified in the re-audit of the `whatsapp_bot` directory, focusing on bug fixes, dead code activation, and UI improvements.

## 1. File-by-File Modification List

### `whatsapp_bot/config.py`
- **Change**: Add `GEMINI_API_KEY: str` to the `Settings` class.
- **Goal**: Resolve Minor Issue #8 (Missing config).

### `whatsapp_bot/whatsapp/states.py`
- **Change**: Remove `REGISTRATION_CONFIRM` from `ConversationState` Enum.
- **Goal**: Resolve Minor Issue #6 (Unused state).

### `whatsapp_bot/whatsapp/flows/interactive_menus.py`
- **Change**: Replace all instances of `%%` with `%` in message strings (IoT status and Govt subsidy text).
- **Change**: In `MENU_MARKET` handler, add a new button/option for "Full Harvest Registration" that sets state to `ConversationState.HARVEST_YARD_ID`.
- **Goal**: Resolve Minor Issue #7 (Literal `%%`) and Dead Code Issue #4 (Harvest Yard entry).

### `whatsapp_bot/whatsapp/flows/main_menu.py`
- **Change**: Refactor `handle_main_menu` to use `whatsapp_client.send_list` instead of `send_buttons`.
- **Change**: Add new menu items for "Transfer Custody" and "Check Batch Status".
- **Goal**: Technical requirement for UI change and entry points for Dead Code Issues #3 and #5.

### `whatsapp_bot/whatsapp/llm_service.py`
- **Change**: Update `IncomingAnalysis` intent list and prompts for `analyze_incoming_text` and `analyze_incoming_audio` to include `TRANSFER` and `VERIFY_BATCH` intents.
- **Goal**: Technical requirement for LLM integration.

### `whatsapp_bot/whatsapp/handler.py`
- **Change**: In `handle_message`, within the `IDLE` / `MAIN_MENU` block:
    - Add logic to handle `TRANSFER` intent or "transfer" keywords $\rightarrow$ trigger `TRANSFER_BATCH_ID`.
    - Add logic to handle `VERIFY_BATCH` intent or "batch status" keywords $\rightarrow$ trigger `BATCH_STATUS_AWAITING_ID`.
    - Map new interactive IDs from the main menu list (`menu_transfer`, `menu_batch_status`) to these states.
- **Goal**: Activate Dead Code Issues #3 and #5.

### `whatsapp_bot/whatsapp/flows/settings.py`
- **Change**: Update `interactive_id` extraction to support both `button_reply` and `list_reply`.
- **Change**: Implement strict validation for language text input; re-prompt the user if the input is not in the mapping instead of defaulting to `"en"`.
- **Goal**: Resolve Bug #1 (Interactive ID) and Bug #2 (Text Fallback).

---

## 2. Detailed Implementation Logic

### New Main Menu (List Format)
The `handle_main_menu` function will now call `send_list` with a structured section.

**Structure:**
- **Body Text**: "👋 Welcome to HoneyBlockChain!\n\nPlease select an option from the menu below:"
- **Button Text**: "Menu"
- **Section Title**: "Main Menu"
- **Rows**:
    1. **Title**: "Honey Box Condition", **Desc**: "Check IoT status" $\rightarrow$ `id: menu_box_condition`
    2. **Title**: "Bees Health & Care", **Desc**: "Disease & Queen status" $\rightarrow$ `id: menu_health_care`
    3. **Title**: "Harvest & Market", **Desc**: "Subsidies, Prices & Registration" $\rightarrow$ `id: menu_market_schemes`
    4. **Title**: "Transfer Custody", **Desc**: "Transfer batch to buyer" $\rightarrow$ `id: menu_transfer`
    5. **Title**: "Check Batch Status", **Desc**: "Verify batch on blockchain" $\rightarrow$ `id: menu_batch_status`

### Entry Points in `handler.py`
When `state` is `IDLE` or `MAIN_MENU`:

1. **Transfer Flow**:
   - If `intent == "TRANSFER"` OR `interactive_id == "menu_transfer"` OR `"transfer"` in `english_text.lower()`:
     - Set state to `ConversationState.TRANSFER_BATCH_ID`.
     - Send message: "Please enter the Batch ID you wish to transfer (e.g., BATCH-XXXX):"

2. **Batch Status Flow**:
   - If `intent == "VERIFY_BATCH"` OR `interactive_id == "menu_batch_status"` OR `"batch status"` in `english_text.lower()`:
     - Set state to `ConversationState.BATCH_STATUS_AWAITING_ID`.
     - Send message: "Please enter the Batch ID to verify its current status on the blockchain:"

### `settings.py` Text Validation Fix
**Existing logic**: `selected_lang = mapping.get(text.lower(), "en")`
**New logic**:
```python
mapping = {"english": "en", "hindi": "hi", "hinglish": "hi", "bengali": "bn", "bangla": "bn"}
text_lower = text.lower()
if text_lower in mapping:
    selected_lang = mapping[text_lower]
else:
    await whatsapp_client.send_text(wa_id, "❌ Invalid language. Please choose from English, Hindi, or Bengali.", lang)
    return # Exit and stay in SETTINGS_CHOOSE_LANGUAGE state
```

---

## 3. Verification Checklist

- [ ] **Issue 1**: Verify that selecting a language from a List Menu (if implemented) or a Button Menu correctly updates the language.
- [ ] **Issue 2**: Enter "French" in language settings; verify the bot re-prompts instead of defaulting to English.
- [ ] **Issue 3**: Trigger "Transfer Custody" via Main Menu list AND via text "I want to transfer a batch"; verify it moves to `TRANSFER_BATCH_ID` state.
- [ ] **Issue 4**: In Market Menu, verify there is an option for "Full Harvest" that moves to `HARVEST_YARD_ID`.
- [ ] **Issue 5**: Trigger "Check Batch Status" via Main Menu list AND via text "check my batch status"; verify it moves to `BATCH_STATUS_AWAITING_ID`.
- [ ] **Issue 6**: Search `states.py` to ensure `REGISTRATION_CONFIRM` is gone.
- [ ] **Issue 7**: Trigger IoT status and Subsidy info; verify `%` is displayed instead of `%%`.
- [ ] **Issue 8**: Check `config.py` for `GEMINI_API_KEY` in the `Settings` class.
- [ ] **UI**: Verify Main Menu is now a List and contains all 5 options.
