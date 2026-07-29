from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from core.security import get_current_user
from database import get_db
from models import User
from schemas import (
    CompletePathStepResponse,
    LearningPathResponse,
    PlacementRequest,
    TodayLearningPlanResponse,
)
from services.learning_path_service import LearningPathService


router = APIRouter(
    prefix="/api/learning-path",
    tags=["Learning Path"],
    redirect_slashes=False,
)


def get_learning_path_service(
    db: AsyncSession = Depends(get_db),
) -> LearningPathService:
    return LearningPathService(db)


@router.get("", response_model=LearningPathResponse)
async def get_learning_path(
    service: LearningPathService = Depends(get_learning_path_service),
    current_user: User = Depends(get_current_user),
):
    return await service.get_path(current_user)


@router.get("/today", response_model=TodayLearningPlanResponse)
async def get_today_plan(
    service: LearningPathService = Depends(get_learning_path_service),
    current_user: User = Depends(get_current_user),
):
    return await service.get_today_plan(current_user)


@router.post("/placement", response_model=LearningPathResponse)
async def save_placement(
    data: PlacementRequest,
    service: LearningPathService = Depends(get_learning_path_service),
    current_user: User = Depends(get_current_user),
):
    return await service.place_user(
        current_user,
        cefr_level=data.cefr_level,
        source=data.source,
    )


@router.post(
    "/steps/{cefr_level}/complete",
    response_model=CompletePathStepResponse,
)
async def complete_step(
    cefr_level: str,
    service: LearningPathService = Depends(get_learning_path_service),
    current_user: User = Depends(get_current_user),
):
    try:
        return await service.complete_step(current_user, cefr_level.upper())
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=str(exc),
        ) from exc
