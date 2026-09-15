import os
from google import genai
from pydantic import BaseModel
from config import settings

class IncomingAnalysis(BaseModel):
    translated_english_text: str
    detected_language: str
    intent: str  # REGISTRATION, HEALTH_CHECK, BOX_CONDITION, MAIN_MENU, CHANGE_LANGUAGE, ASK_DOUBT, HIVE_STATUS, UNKNOWN

# Load Gemini API Key
api_key = getattr(settings, "GEMINI_API_KEY", os.getenv("GEMINI_API_KEY"))
client = genai.Client(api_key=api_key) if api_key else None

def analyze_incoming_text(text: str) -> IncomingAnalysis:
    """
    Takes user input in any language.
    Returns the English translation, the detected language, and the categorized intent.
    """
    if not client:
        return IncomingAnalysis(translated_english_text=text, detected_language="en", intent="UNKNOWN")
        
    prompt = f"""
    Analyze the following user message sent to a Beekeeper WhatsApp Bot.

    1. Translate the message into English.
    2. Detect the original language (e.g., 'hi' for Hindi/Hinglish, 'en' for English, 'bn' for Bengali).
    3. Categorize the INTENT into one of the following:
       - REGISTRATION (User wants to register or join)
       - ASK_DOUBT (User is asking a question about bees, harvesting, or asking for help)
       - HIVE_STATUS (User wants to check the IoT status of their hive or box condition)
       - MAIN_MENU (User is saying hi, hello, or asking for the menu)
       - CHANGE_LANGUAGE (User wants to change the bot's language or is asking about language settings)
       - UNKNOWN (Does not fit any category)

    User message: "{text}"
    """
    
    try:
        response = client.models.generate_content(
            model=settings.GEMINI_MODEL,
            contents=prompt,
            config={
                'response_mime_type': 'application/json',
                'response_schema': IncomingAnalysis,
                'temperature': 0.1
            },
        )
        # Guard: response.parsed can be None if Gemini returns malformed JSON
        parsed = response.parsed
        if parsed is None:
            print(f"LLM Text Analysis Warning: response.parsed is None, using fallback")
            return IncomingAnalysis(translated_english_text=text, detected_language="en", intent="UNKNOWN")
        return parsed
    except Exception as e:
        print(f"LLM Incoming Analysis Error: {e}")
        return IncomingAnalysis(translated_english_text=text, detected_language="en", intent="UNKNOWN")

def analyze_incoming_audio(audio_bytes: bytes) -> IncomingAnalysis:
    """
    Takes a WhatsApp Voice Note (audio/ogg).
    Returns the English translation, the detected language, and the categorized intent.
    """
    if not client:
        return IncomingAnalysis(translated_english_text="[Audio Error]", detected_language="en", intent="UNKNOWN")
        
    prompt = """
    Analyze this voice note sent by a farmer to a Beekeeper WhatsApp Bot.

    1. Transcribe the audio and translate the message into English.
    2. Detect the original language (e.g., 'hi' for Hindi/Hinglish, 'en' for English, 'bn' for Bengali).
    3. Categorize the INTENT into one of the following:
       - REGISTRATION (User wants to register or join)
       - ASK_DOUBT (User is asking a question about bees, harvesting, or asking for help)
       - HIVE_STATUS (User wants to check the IoT status of their hive or box condition)
       - MAIN_MENU (User is saying hi, hello, or asking for the menu)
       - CHANGE_LANGUAGE (User wants to change the bot's language or is asking about language settings)
       - UNKNOWN (Does not fit any category)
    """
    
    try:
        from google.genai import types
        audio_part = types.Part.from_bytes(data=audio_bytes, mime_type='audio/ogg')
        response = client.models.generate_content(
            model=settings.GEMINI_MODEL,
            contents=[prompt, audio_part],
            config={
                'response_mime_type': 'application/json',
                'response_schema': IncomingAnalysis,
                'temperature': 0.1
            },
        )
        # Guard: response.parsed can be None if Gemini returns malformed JSON
        parsed = response.parsed
        if parsed is None:
            print(f"LLM Audio Analysis Warning: response.parsed is None, using fallback")
            return IncomingAnalysis(translated_english_text="[Audio processing failed]", detected_language="en", intent="UNKNOWN")
        return parsed
    except Exception as e:
        print(f"LLM Audio Analysis Error: {e}")
        return IncomingAnalysis(translated_english_text="[Audio processing failed]", detected_language="en", intent="UNKNOWN")

def translate_outgoing_text(english_text: str, target_language: str) -> str:
    """
    Translates the bot's English response into the user's preferred language.
    """
    if not client or target_language == "en":
        return english_text
        
    prompt = f"""
    Translate the following English message for a Beekeeper into the language code '{target_language}'.
    Ensure the translation is natural and polite. Do not add any extra commentary, just return the translated text.
    
    English message:
    {english_text}
    """
    
    try:
        response = client.models.generate_content(
            model=settings.GEMINI_MODEL,
            contents=prompt,
            config={'temperature': 0.1}
        )
        return response.text.strip()
    except Exception as e:
        print(f"LLM Outgoing Translation Error: {e}")
        return english_text
