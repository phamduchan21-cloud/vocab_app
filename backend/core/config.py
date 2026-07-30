from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    # Supabase configuration
    SUPABASE_URL: str = ""
    SUPABASE_ANON_KEY: str = ""
    SUPABASE_JWT_SECRET: str = ""

    # Database URL (default: SQLite for local dev without Supabase)
    DATABASE_URL: str = "sqlite+aiosqlite:///./app.db"

    # Frontend URL for CORS
    FRONTEND_URL: str = "http://localhost:5173"

    # Runtime logging
    LOG_LEVEL: str = "INFO"

    # AI API Keys (optional — service falls back gracefully if not set)
    XAI_API_KEY: Optional[str] = None
    XAI_MODEL: str = "grok-4.3"
    GEMINI_API_KEY: Optional[str] = None
    OPENAI_API_KEY: Optional[str] = None
    OPENAI_MODEL: str = "gpt-4o-mini"
    AI_PROVIDER_TIMEOUT_SECONDS: float = 12.0
    AI_REQUEST_TIMEOUT_SECONDS: float = 28.0
    AI_CIRCUIT_FAILURE_THRESHOLD: int = 3
    AI_CIRCUIT_RECOVERY_SECONDS: int = 60

    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8",
        "case_sensitive": True,
    }


settings = Settings()
