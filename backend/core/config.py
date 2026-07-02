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

    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8",
        "case_sensitive": True,
    }


settings = Settings()
