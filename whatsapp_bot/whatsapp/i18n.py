"""
i18n.py - Localisation strings for the HoneyChain WhatsApp Bot.

Usage:
    from whatsapp.i18n import t
    msg = t("hi", "harvest.step1")
    msg = t("en", "transfer.success").format(batch_id="BATCH-123", buyer="91...")
"""

STRINGS: dict = {
    "en": {
        "general": {
            "cancelled": "Cancelled. Send hi to return to the menu.",
            "invalid_number": "Please enter a valid number (digits only).",
            "error": "Something went wrong. Please try again.",
            "not_registered": "Welcome to HoneyChain! Please send hi to register.",
        },
        "harvest": {
            "step1": (
                "New Harvest Registration\n\n"
                "Step 1/4: What is the name or ID of your apiary / yard?\n"
                "(e.g., Punjab-Yard-1)"
            ),
            "step2": "Step 2/4: How many hives were harvested? (Enter a number)",
            "step3": "Step 3/4: What is the total weight in kilograms? (e.g., 25.5)",
            "step4": (
                "Step 4/4: What is the floral source / honey type?\n"
                "(e.g., Mustard, Litchi, Multiflora)"
            ),
            "success": (
                "Harvest Registered on HoneyChain!\n\n"
                "Batch ID: {batch_id}\n"
                "Quantity: {qty} kg\n"
                "Type: {type}\n\n"
                "Your harvest is now traceable on the blockchain."
            ),
        },
        "transfer": {
            "step1": (
                "Transfer Custody\n\n"
                "Please enter the Batch ID you want to transfer:\n"
                "(e.g., BATCH-A1B2C3D4)"
            ),
            "step2": (
                "Please enter the buyer's WhatsApp number\n"
                "(digits only, e.g. 919876543210):"
            ),
            "success": (
                "Custody Transferred!\n\n"
                "Batch: {batch_id}\n"
                "New Owner: +{buyer}\n\n"
                "The transfer has been recorded on HoneyChain."
            ),
        },
    },
}


def t(lang: str, key: str) -> str:
    """
    Retrieve a localised string by dotted key, e.g. t('hi', 'harvest.step1').

    Resolution order:
      1. Look in STRINGS[lang][...key parts...]
      2. Fall back to STRINGS['en'][...key parts...]
      3. Return the raw key string (never raises)
    """
    parts = key.split(".")
    for language in (lang, "en"):
        node = STRINGS.get(language, {})
        for part in parts:
            if isinstance(node, dict):
                node = node.get(part)
            else:
                node = None
                break
        if isinstance(node, str):
            return node
    # Last resort - return key so callers never crash on a missing translation
    return key
