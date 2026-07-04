import math

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession

from database import get_db
from schemas import (
    MockTestGenerateRequest,
    MockTestGenerateResponse,
    MockTestSubmit,
    MockTestResultResponse,
    PaginatedResponse,
)
from services.mock_test_service import MockTestService
from core.security import get_current_user
from models import User

router = APIRouter(prefix="/api/mock-tests", tags=["Mock Tests"], redirect_slashes=False)


def get_mock_test_service(db: AsyncSession = Depends(get_db)) -> MockTestService:
    return MockTestService(db)


@router.post("/generate", response_model=MockTestGenerateResponse)
async def generate_mock_test(
    data: MockTestGenerateRequest,
    service: MockTestService = Depends(get_mock_test_service),
    current_user: User = Depends(get_current_user),
):
    """Tạo bài kiểm tra từ vựng tiếng Anh từ từ vựng của người dùng."""
    try:
        test_id, questions, total, duration = await service.generate(
            user_id=current_user.id,
            level=data.level,
            topic=data.topic,
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )

    return MockTestGenerateResponse(
        id=test_id,
        level=data.level,
        questions=questions,
        total=total,
        duration_minutes=duration,
    )


@router.post("/submit", response_model=MockTestResultResponse)
async def submit_mock_test(
    data: MockTestSubmit,
    service: MockTestService = Depends(get_mock_test_service),
    current_user: User = Depends(get_current_user),
):
    """Nộp bài kiểm tra và nhận kết quả chấm điểm + xếp loại A/B/C/D."""
    if not data.answers:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Không có câu trả lời nào để chấm điểm",
        )

    result = await service.submit(
        user_id=current_user.id,
        test_id=data.test_id,
        answers=data.answers,
    )
    return result


@router.get("/available-topics")
async def get_available_topics(
    service: MockTestService = Depends(get_mock_test_service),
    current_user: User = Depends(get_current_user),
):
    """Lấy danh sách chủ đề có thể kiểm tra (từ user vocab + seed data)."""
    topics = await service.get_available_topics(user_id=current_user.id)
    return {"topics": topics}


@router.get("/history", response_model=PaginatedResponse)
async def get_mock_test_history(
    page: int = Query(default=1, ge=1),
    limit: int = Query(default=20, ge=1, le=100),
    service: MockTestService = Depends(get_mock_test_service),
    current_user: User = Depends(get_current_user),
):
    """Lấy lịch sử các bài thi thử đã làm."""
    items, total = await service.get_history(
        user_id=current_user.id,
        page=page,
        limit=limit,
    )

    pages = math.ceil(total / limit) if total > 0 else 0

    return PaginatedResponse(
        items=items,
        total=total,
        page=page,
        pages=pages,
        limit=limit,
    )
