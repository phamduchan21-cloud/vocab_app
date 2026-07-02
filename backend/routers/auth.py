from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
import httpx

from core.config import settings
from database import get_db
from schemas import UserCreate, UserLogin, UserResponse, AuthResponse
from core.security import get_current_user
from services.auth_service import AuthService
from models import User

router = APIRouter(prefix="/api/auth", tags=["Auth"], redirect_slashes=False)

SUPABASE_API_URL = f"{settings.SUPABASE_URL}/auth/v1"


@router.post("/register", response_model=AuthResponse)
async def register(data: UserCreate, db: AsyncSession = Depends(get_db)):
    """Đăng ký tài khoản mới qua Supabase Auth."""
    if not settings.SUPABASE_URL:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Supabase chưa được cấu hình. Vui lòng kiểm tra biến môi trường SUPABASE_URL.",
        )

    # Call Supabase Auth REST API to sign up
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{SUPABASE_API_URL}/signup",
            headers={
                "apikey": settings.SUPABASE_ANON_KEY,
                "Content-Type": "application/json",
            },
            json={
                "email": data.email,
                "password": data.password,
            },
        )

    if response.status_code != 200:
        error_detail = response.json().get("msg", "Đăng ký thất bại")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=error_detail,
        )

    supabase_data = response.json()
    supabase_user = supabase_data.get("user", supabase_data.get("data", {}).get("user", {}))
    supabase_user_id = supabase_user.get("id")
    email = supabase_user.get("email", data.email)

    # Create or get user in local DB
    user = await AuthService.get_or_create_user(db, supabase_user_id, email)

    # Update username if provided
    if data.username and user:
        user.username = data.username
        await db.commit()
        await db.refresh(user)

    access_token = supabase_data.get("access_token", "")

    return AuthResponse(
        access_token=access_token,
        user=UserResponse(
            id=str(user.id),
            email=user.email,
            username=user.username,
            is_premium=user.is_premium,
            created_at=user.created_at,
        ),
    )


@router.post("/login", response_model=AuthResponse)
async def login(data: UserLogin, db: AsyncSession = Depends(get_db)):
    """Đăng nhập bằng email và password qua Supabase Auth."""
    if not settings.SUPABASE_URL:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Supabase chưa được cấu hình. Vui lòng kiểm tra biến môi trường SUPABASE_URL.",
        )

    # Call Supabase Auth REST API to sign in
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{SUPABASE_API_URL}/token?grant_type=password",
            headers={
                "apikey": settings.SUPABASE_ANON_KEY,
                "Content-Type": "application/json",
            },
            json={
                "email": data.email,
                "password": data.password,
            },
        )

    if response.status_code != 200:
        error_detail = response.json().get("msg", "Đăng nhập thất bại")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=error_detail,
        )

    supabase_data = response.json()
    supabase_user = supabase_data.get("user", {})
    supabase_user_id = supabase_user.get("id")
    email = supabase_user.get("email", data.email)
    access_token = supabase_data.get("access_token", "")

    # Create or get user in local DB
    user = await AuthService.get_or_create_user(db, supabase_user_id, email)

    return AuthResponse(
        access_token=access_token,
        user=UserResponse(
            id=str(user.id),
            email=user.email,
            username=user.username,
            is_premium=user.is_premium,
            created_at=user.created_at,
        ),
    )


@router.get("/me", response_model=UserResponse)
async def get_me(current_user: User = Depends(get_current_user)):
    """Lấy thông tin người dùng hiện tại."""
    return UserResponse(
        id=str(current_user.id),
        email=current_user.email,
        username=current_user.username,
        is_premium=current_user.is_premium,
        created_at=current_user.created_at,
    )
