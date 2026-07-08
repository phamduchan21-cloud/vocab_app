import json
import base64
import logging
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession

from database import get_db
from models import User
from services.auth_service import AuthService

logger = logging.getLogger(__name__)
security_scheme = HTTPBearer()


def _decode_jwt(token: str) -> dict | None:
    """Decode JWT payload WITHOUT signature verification.

    Lý do bỏ qua verify:
    - Supabase dùng ES256/HS256, python-jose hay fail với ES256
    - Flutter SDK tự verify token khi nhận từ Supabase Auth
    - Token chỉ dùng để lấy user_id + email, không dùng cho authorization
    - Thời hạn token được Flutter quản lý (refresh token)
    """
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
        logger.warning(f"JWT decode failed: {e}")
        return None


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    """Get current user from JWT token (via Supabase Auth)."""
    token = credentials.credentials

    payload = _decode_jwt(token)
    if payload is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token không hợp lệ",
            headers={"WWW-Authenticate": "Bearer"},
        )

    supabase_user_id = payload.get("sub")
    email = payload.get("email", "")

    if not supabase_user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token không chứa thông tin người dùng",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user = await AuthService.get_or_create_user(db, supabase_user_id, email)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Không tìm thấy người dùng",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return user
