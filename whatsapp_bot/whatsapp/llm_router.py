import os
from google import genai
from pydantic import BaseModel
from config import settings

class UserIntent(BaseModel):
    intent: str
    detected_language: str
    confidence: float

# Ensure the GEMINI API Key is set in config (will fallback to os.environ)
api_key = getattr(settings, "GEMINI_API_KEY", os.getenv("GEMINI_API_KEY"))
client = genai.Client(api_key=api_key) if api_key else None

def classify_intent(text: str) -> UserIntent:
    if not client:
        # Fallback if no API key
        return UserIntent(intent="UNKNOWN", detected_language="en", confidence=0.0)
        
    prompt = f"""
    You are an intent classifier for a WhatsApp bot used by beekeepers in India.
    Analyze the user's message, which may be in English, Hindi, Hinglish, Bengali, Benglish, or other Indian languages.
    
    Determine the INTENT from these options:
    - DIAGNOSTICS (User wants to check hive health, disease, queen, upload photo/audio)
    - REGISTRATION (User wants to register, join, create profile)
    - HARVEST (User wants to log harvest, honey collection)
    - TRANSFER (User wants to sell or transfer batch)
    - VERIFY (User wants to verify or trace a batch)
    - CHANGE_LANGUAGE (User wants to change the bot language, e.g. "hindi", "english", "bhasha badlo")
    - MAIN_MENU (User just says hi, hello, menu, or asks for options)
    - UNKNOWN (If it doesn't match any of the above clearly)
    
    Also detect the language (e.g., "en", "hi", "bn"). If it's Hinglish/Roman Hindi, return "hi". 
    
    User message: "{text}"
    """
    
    try:
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=prompt,
            config={
                'response_mime_type': 'application/json',
                'response_schema': UserIntent,
                'temperature': 0.1
            },
        )
        return response.parsed
    except Exception as e:
        print(f"LLM Classification Error: {e}")
        return UserIntent(intent="UNKNOWN", detected_language="en", confidence=0.0)
