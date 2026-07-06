import uuid
import json
import base64
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from models import User


class AuthService:
    """
    Xác thực JWT từ Supabase Auth.
    Flutter đăng nhập qua supabase_flutter, gửi token lên FastAPI.
    Backend decode JWT claims và đồng bộ user vào SQLite.
    """

    @staticmethod
    def _decode_jwt_payload(token: str) -> dict | None:
        """Decode JWT payload without signature verification (dev-only)."""
        try:
            parts = token.split(".")
            if len(parts) != 3:
                return None
            payload_b64 = parts[1]
            padding = 4 - len(payload_b64) % 4
            if padding != 4:
                payload_b64 += "=" * padding
            decoded = base64.urlsafe_b64decode(payload_b64)
            return json.loads(decoded)
        except Exception as e:
            print(f"[AuthService] Token decode error: {e}")
            return None

    @staticmethod
    async def verify_token(token: str) -> dict | None:
        """Decode JWT token claims."""
        return AuthService._decode_jwt_payload(token)

    @staticmethod
    async def get_or_create_user(
        db: AsyncSession,
        supabase_user_id: str,
        email: str,
    ) -> User | None:
        """Get existing user or create a new one.

        SQLite: id lưu dạng string (UUID từ Supabase).
        PostgreSQL: tương tự, dùng string.
        """
        try:
            query = select(User).where(User.id == supabase_user_id)
            result = await db.execute(query)
            user = result.scalar_one_or_none()

            if not user:
                username = email.split("@")[0] if email else "user"
                user = User(
                    id=supabase_user_id,
                    email=email,
                    username=username,
                    is_premium=False,
                )
                db.add(user)
                await db.commit()
                await db.refresh(user)

            return user
        except Exception as e:
            print(f"[AuthService] Loi tao user: {e}")
            await db.rollback()
            return None
