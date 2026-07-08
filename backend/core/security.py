import logging
from jose import jwt, JWTError
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
import httpx

from database import get_db
from models import User
from core.config import settings
from services.auth_service import AuthService

logger = logging.getLogger(__name__)
security_scheme = HTTPBearer()


async def _verify_token_via_supabase_api(token: str) -> dict | None:
    """Verify JWT by calling Supabase Auth REST API."""
    if not settings.SUPABASE_URL:
        return None
    url = f"{settings.SUPABASE_URL}/auth/v1/user"
    try:
        async with httpx.AsyncClient(timeout=5) as client:
            resp = await client.get(
                url, headers={
                    "apikey": settings.SUPABASE_ANON_KEY,
                    "Authorization": f"Bearer {token}",
                },
            )
        if resp.status_code == 200:
            return resp.json()
    except Exception as e:
        logger.warning(f"Supabase API verify failed: {e}")
    return None


def _verify_token_local(token: str) -> dict | None:
    """Verify JWT using SUPABASE_JWT_SECRET (fallback)."""
    if not settings.SUPABASE_JWT_SECRET:
        return None
    try:
        return jwt.decode(
            token,
            settings.SUPABASE_JWT_SECRET,
            algorithms=["HS256", "ES256"],
            options={"verify_aud": False},
        )
    except JWTError as e:
        logger.warning(f"Local JWT verify failed: {e}")
        return None


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    """Verify JWT token and return the current user.

    Strategy:
    1. Try Supabase Auth REST API (most reliable with ES256 tokens)
    2. Fallback to local JWT decode with SUPABASE_JWT_SECRET
    3. Both fail → 401
    """
    token = credentials.credentials

    # Try API first
    user_data = await _verify_token_via_supabase_api(token)
    if user_data:
        supabase_user_id = user_data.get("id")
        email = user_data.get("email", "")
    else:
        # Fallback to local verify
        payload = _verify_token_local(token)
        if payload is None:
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
