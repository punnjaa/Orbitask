from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env")
    supabase_url: str
    supabase_service_key: str
    gemini_api_key: str
    gemini_model: str = "gemini-3.8-flash"  # เช็กชื่อรุ่นล่าสุดใน Google AI Studio
    line_channel_secret: str
    line_channel_token: str
    cron_secret: str

settings = Settings()
