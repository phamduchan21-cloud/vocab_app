import logging
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
import httpx

from models import User
from core.config import settings

logger = logging.getLogger(__name__)

SUPABASE_API_URL = f"{settings.SUPABASE_URL}/auth/v1" if settings.SUPABASE_URL else None


class AuthService:
    """
    Xác thực JWT từ Supabase Auth.
    Flutter đăng nhập qua supabase_flutter, gửi token lên FastAPI.
    Backend verify JWT signature và đồng bộ user vào DB.
    """

    @staticmethod
    async def _supabase_request(endpoint: str, json_data: dict) -> dict:
        """Proxy request to Supabase Auth REST API."""
        if not SUPABASE_API_URL:
            raise ValueError("Supabase chưa được cấu hình.")
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f"{SUPABASE_API_URL}{endpoint}",
                headers={
                    "apikey": settings.SUPABASE_ANON_KEY,
                    "Content-Type": "application/json",
                },
                json=json_data,
            )
        data = resp.json()
        if resp.status_code not in (200, 201):
            msg = data.get("msg", data.get("error_description", "Yêu cầu thất bại"))
            raise httpx.HTTPStatusError(msg, request=resp.request, response=resp)
        return data

    @staticmethod
    async def sign_up(email: str, password: str) -> dict:
        """Register via Supabase Auth."""
        return await AuthService._supabase_request("/signup", {
            "email": email,
            "password": password,
        })

    @staticmethod
    async def sign_in(email: str, password: str) -> dict:
        """Login via Supabase Auth (password grant)."""
        return await AuthService._supabase_request("/token?grant_type=password", {
            "email": email,
            "password": password,
        })

    @staticmethod
    def _extract_user(data: dict) -> tuple[str, str]:
        """Extract (user_id, email) from Supabase response."""
        user = data.get("user", data.get("data", {}).get("user", {}))
        return user.get("id", ""), user.get("email", "")

    @staticmethod
    async def get_or_create_user(
        db: AsyncSession,
        supabase_user_id: str,
        email: str,
    ) -> User | None:
        """Get existing user or create a new one."""
        try:
            result = await db.execute(select(User).where(User.id == supabase_user_id))
            user = result.scalar_one_or_none()
            if not user:
                username = email.split("@")[0] if email else "user"
                user = User(
                    id=supabase_user_id, email=email,
                    username=username, is_premium=False,
                )
                db.add(user)
                await db.commit()
                await db.refresh(user)
            return user
        except Exception as e:
            logger.error(f"Failed to create user: {e}")
            await db.rollback()
            return None
