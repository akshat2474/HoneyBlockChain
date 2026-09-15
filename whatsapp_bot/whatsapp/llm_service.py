import os
from google import genai
from pydantic import BaseModel
from config import settings

class IncomingAnalysis(BaseModel):
    translated_english_text: str
    detected_language: str
    intent: str  # REGISTRATION, HEALTH_CHECK, BOX_CONDITION, MAIN_MENU, CHANGE_LANGUAGE, ASK_DOUBT, HIVE_STATUS, TRANSFER, VERIFY_BATCH, UNKNOWN
    requested_language_code: str = ""  # If user asks for a specific language (e.g. 'te', 'hi'), output code here. Else empty.

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
    2. Detect the original language (e.g., 'hi' for Hindi/Hinglish, 'en' for English, 'bn' for Bengali, 'te' for Telugu).
    3. Categorize the INTENT into one of the following:
       - REGISTRATION (User wants to register or join)
       - ASK_DOUBT (User is asking a question about bees, harvesting, or asking for help)
       - HIVE_STATUS (User wants to check the IoT sensor status of their hive or box)
       - HEALTH_CHECK (User wants to check bee health, diseases, queen status, or hive condition)
       - HARVEST_MARKET (User wants to register a harvest, check honey prices, or view government subsidies)
       - MAIN_MENU (User is saying hi, hello, or asking for the menu)
       - CHANGE_LANGUAGE (User wants to change the bot's language, OR user just typed the name of a language like "Telugu", "Marathi", "Tamil")
       - TRANSFER (User wants to transfer custody of a batch to someone else)
       - VERIFY_BATCH (User wants to check the status or verify a batch ID on the blockchain)
       - UNKNOWN (Does not fit any category)
    4. If the user explicitly asks to speak in a specific language (e.g. "Talk to me in Telugu", "Hindi please", or just "Marathi"), set `requested_language_code` to the 2-letter ISO 639-1 code for that language (e.g. 'te' for Telugu, 'mr' for Marathi, 'ta' for Tamil, 'hi' for Hindi). Otherwise, leave it empty.

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
    2. Detect the original language (e.g., 'hi' for Hindi/Hinglish, 'en' for English, 'bn' for Bengali, 'te' for Telugu).
    3. Categorize the INTENT into one of the following:
       - REGISTRATION (User wants to register or join)
       - ASK_DOUBT (User is asking a question about bees, harvesting, or asking for help)
       - HIVE_STATUS (User wants to check the IoT status of their hive or box condition)
       - MAIN_MENU (User is saying hi, hello, or asking for the menu)
       - CHANGE_LANGUAGE (User wants to change the bot's language, OR user just typed the name of a language like "Telugu", "Marathi", "Tamil")
       - TRANSFER (User wants to transfer custody of a batch to someone else)
       - VERIFY_BATCH (User wants to check the status or verify a batch ID on the blockchain)
       - UNKNOWN (Does not fit any category)
    4. If the user explicitly asks to speak in a specific language, set `requested_language_code` to the 2-letter ISO 639-1 code for that language (e.g. 'te' for Telugu, 'mr' for Marathi, 'ta' for Tamil). Otherwise, leave it empty.
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

async def generate_onboarding_response(user_text: str, lang: str = "en") -> tuple[str, bool]:
    """
    Generates a friendly introduction to HoneyChain and the Pollinator App.
    Returns (response_text, should_start_registration).
    """
    if not client:
        return "Welcome to HoneyChain! We help beekeepers track their honey and get fair prices using the Pollinator App. Would you like to register now or know more about it?", True

    project_context = """
    You are the welcoming ambassador for 'HoneyChain' and the 'Pollinator App'.

    Project Context:
    - HoneyChain is a blockchain-based ecosystem for the honey industry.
    - The Pollinator App is the mobile interface for farmers/beekeepers.
    - Goal: To bring transparency to the honey supply chain, eliminate middlemen, and ensure beekeepers get fair prices for their quality honey.
    - Features: IoT hive monitoring, blockchain-verified harvest batches, direct market access, and honey quality verification.
    - Tone: Professional, empathetic, and encouraging. You are talking to farmers who may not be tech-savvy.
    """

    prompt = f"""
    {project_context}

    The user has just sent a message: "{user_text}"

    Task:
    1. If the user is saying 'hi' or 'hello', give a warm, 2-sentence introduction to HoneyChain and the Pollinator App. Explain how it helps them get better prices and transparency.
       CRITICAL: You MUST end the response with a clear call-to-action. Ask them if they would like to register now or if they want to know more about how the Pollinator App works.

    2. If the user is asking a question, answer it briefly using the project context.
       CRITICAL: After answering, always ask if they are ready to register or if they have any other questions about the Pollinator App. Remind them that voice notes are welcome for any queries.

    3. If the user seems ready to join, register, or says 'yes', signal that registration should start.

    Response format (JSON):
    {{
        "response": "Your friendly response in English, including a clear question or call-to-action at the end",
        "ready_to_register": true/false
    }}
    """

    try:
        response = client.models.generate_content(
            model=settings.GEMINI_MODEL,
            contents=prompt,
            config={
                'response_mime_type': 'application/json',
                'temperature': 0.7
            },
        )
        import json
        res_data = json.loads(response.text)
        return res_data.get("response", ""), res_data.get("ready_to_register", False)
    except Exception as e:
        print(f"Onboarding LLM Error: {e}")
        return "Welcome to HoneyChain! We're bringing blockchain transparency to beekeeping. Ready to register?", True
