from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    WHATSAPP_PHONE_NUMBER_ID: str
    WHATSAPP_BUSINESS_ACCOUNT_ID: str
    WHATSAPP_ACCESS_TOKEN: str
    WHATSAPP_VERIFY_TOKEN: str
    WHATSAPP_APP_SECRET: str
    WHATSAPP_API_VERSION: str = "v25.0"
    REDIS_URL: str = "redis://localhost:6379"
    DATABASE_URL: str = "sqlite:///./honeychain.db"

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

settings = Settings()
