import math
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession

from database import get_db
from schemas import (
    QuizGenerateRequest,
    QuizGenerateResponse,
    QuizSubmit,
    QuizResultResponse,
    QuizCategoryResponse,
    QuizTopicResponse,
    PaginatedResponse,
)
from services.quiz_service import QuizService
from core.security import get_current_user
from models import User
from question_bank import get_available_topics

router = APIRouter(prefix="/api/quiz", tags=["Quiz"], redirect_slashes=False)


def get_quiz_service(db: AsyncSession = Depends(get_db)) -> QuizService:
    return QuizService(db)


@router.get("/categories", response_model=list[QuizCategoryResponse])
async def get_categories(
    service: QuizService = Depends(get_quiz_service),
):
    """Lấy danh sách các dạng bài quiz."""
    categories = await service.get_categories()
    return [
        QuizCategoryResponse(
            id=str(c.id),
            title=c.title,
            description=c.description,
            icon=c.icon,
        )
        for c in categories
    ]


@router.get("/topics", response_model=list[QuizTopicResponse])
async def get_topics():
    """Lay cac chu de co san trong ngan hang cau hoi."""
    return get_available_topics()


@router.post("/generate", response_model=QuizGenerateResponse)
async def generate_quiz(
    data: QuizGenerateRequest,
    service: QuizService = Depends(get_quiz_service),
    current_user: User = Depends(get_current_user),
):
    """Sinh câu hỏi quiz từ từ vựng của người dùng."""
    try:
        questions, total = await service.generate_quiz(
            user_id=current_user.id,
            count=data.count,
            skill_type=data.skill_type,
            topic=data.topic,
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )

    return QuizGenerateResponse(
        questions=questions,
        total=total,
    )


@router.post("/submit", response_model=QuizResultResponse)
async def submit_quiz(
    data: QuizSubmit,
    service: QuizService = Depends(get_quiz_service),
    current_user: User = Depends(get_current_user),
):
    """Nộp bài quiz và nhận kết quả chấm điểm."""
    if not data.answers:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Không có câu trả lời nào để chấm điểm",
        )

    result = await service.submit_quiz(
        user_id=current_user.id,
        quiz_type=data.quiz_type,
        skill_type=data.skill_type,
        topic=data.topic,
        answers=data.answers,
    )
    return result


@router.get("/history", response_model=PaginatedResponse)
async def get_quiz_history(
    page: int = Query(default=1, ge=1),
    limit: int = Query(default=20, ge=1, le=100),
    skill_type: Optional[str] = Query(default=None),
    service: QuizService = Depends(get_quiz_service),
    current_user: User = Depends(get_current_user),
):
    """Lấy lịch sử bài quiz đã làm, có thể lọc theo skill_type."""
    items, total = await service.get_history(
        user_id=current_user.id,
        page=page,
        limit=limit,
        skill_type=skill_type,
    )

    pages = math.ceil(total / limit) if total > 0 else 0

    quiz_responses = [
        QuizResultResponse(
            id=str(q.id),
            quiz_type=q.quiz_type,
            skill_type=q.skill_type,
            topic=q.topic,
            total_questions=q.total_questions,
            correct_answers=q.correct_answers,
            score_percent=float(q.score_percent),
            completed_at=q.completed_at,
            details=q.answers,
        )
        for q in items
    ]

    return PaginatedResponse(
        items=quiz_responses,
        total=total,
        page=page,
        pages=pages,
        limit=limit,
    )
