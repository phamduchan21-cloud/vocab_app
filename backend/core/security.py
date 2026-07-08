import json
import base64
import logging
from jose import jwt, JWTError
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession

from database import get_db
from models import User
from core.config import settings
from services.auth_service import AuthService

logger = logging.getLogger(__name__)
security_scheme = HTTPBearer()


def _verify_jwt(token: str) -> dict:
    """Verify JWT signature using Supabase JWT secret and return payload.

    Supabase uses ES256 (or HS256) — python-jose handles both.
    """
    try:
        payload = jwt.decode(
            token,
            settings.SUPABASE_JWT_SECRET,
            algorithms=["HS256", "ES256"],
            options={"verify_aud": False},
        )
        return payload
    except JWTError as e:
        logger.error(f"JWT verification failed: {e}")
        raise ValueError(f"Token không hợp lệ: {e}")


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    """Verify JWT token and return the current user.

    Flutter gửi Supabase JWT token → verify signature bằng SUPABASE_JWT_SECRET
    → lấy user_id + email → sync user vào local DB.
    """
    token = credentials.credentials

    try:
        payload = _verify_jwt(token)
    except Exception as e:
        logger.warning(f"Token verification failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token không hợp lệ hoặc đã hết hạn",
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
