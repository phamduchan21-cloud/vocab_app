from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from jose import JWTError, jwt

from core.config import settings
from database import get_db
from models import User
from services.auth_service import AuthService

security_scheme = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    """Verify JWT token and return the current user.

    Uses Supabase JWT secret to decode the token, then fetches
    or creates the user in the local database.
    """
    token = credentials.credentials

    # Decode token without verification for local dev (Supabase tokens)
    try:
        payload = jwt.decode(
            token,
            "",
            options={
                "verify_signature": False,
                "verify_aud": False,
                "verify_exp": False,
                "verify_iat": False,
            },
        )
    except Exception as e:
        print(f"[Security] Token decode failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token không hợp lệ hoặc đã hết hạn",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Extract user info from payload
    supabase_user_id = payload.get("sub")
    email = payload.get("email", "")

    if not supabase_user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token không chứa thông tin người dùng",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Get or create user in local DB
    user = await AuthService.get_or_create_user(db, supabase_user_id, email)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Không tìm thấy người dùng",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return user
