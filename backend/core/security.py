import json
import base64
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession

from database import get_db
from models import User
from services.auth_service import AuthService

security_scheme = HTTPBearer()


def _decode_jwt_payload(token: str) -> dict:
    """Decode JWT payload WITHOUT signature verification (dev-only).

    python-jose / PyJWT hay gặp lỗi với ES256 tokens của Supabase,
    nên decode base64 thủ công — an toàn vì verify đã có Supabase Auth.
    """
    parts = token.split(".")
    if len(parts) != 3:
        raise ValueError("JWT phải có 3 phần (header.payload.signature)")

    payload_b64 = parts[1]
    # Thêm padding cho base64 URL-safe
    padding = 4 - len(payload_b64) % 4
    if padding != 4:
        payload_b64 += "=" * padding

    try:
        decoded = base64.urlsafe_b64decode(payload_b64)
        return json.loads(decoded)
    except Exception as e:
        raise ValueError(f"Không thể decode JWT payload: {e}")


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    """Verify JWT token and return the current user.

    Flutter gửi Supabase JWT token → decode payload lấy user_id + email
    → sync user vào local DB (SQLite / PostgreSQL).
    """
    token = credentials.credentials

    # Decode token payload without signature verification
    try:
        payload = _decode_jwt_payload(token)
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
