import json
import os

# Cache dictionaries in memory
_locales = {}

def load_locales():
    global _locales
    locales_dir = os.path.join(os.path.dirname(__file__), "..", "locales")
    for filename in os.listdir(locales_dir):
        if filename.endswith(".json"):
            lang_code = filename.split(".")[0]
            filepath = os.path.join(locales_dir, filename)
            with open(filepath, "r", encoding="utf-8") as f:
                _locales[lang_code] = json.load(f)

# Initialize on import
load_locales()

def t(lang: str, key_path: str) -> str:
    """
    Get translated string. 
    Usage: t("hi", "menu.welcome")
    Falls back to 'en' if key or language is missing.
    """
    keys = key_path.split(".")
    
    # Try preferred language
    data = _locales.get(lang, _locales.get("en", {}))
    
    for key in keys:
        if isinstance(data, dict) and key in data:
            data = data[key]
        else:
            # Fallback to English
            data = _locales.get("en", {})
            for k in keys:
                if isinstance(data, dict) and k in data:
                    data = data[k]
                else:
                    return key_path # Return key path if completely missing
            break
            
    return data if isinstance(data, str) else key_path
