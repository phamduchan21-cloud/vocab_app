from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from database import get_db
from schemas import (
    DashboardResponse,
    UserStatsResponse,
    TodayReviewResponse,
    TopicProgressResponse,
    WeeklyActivityResponse,
    SkillsResponse,
)
from services.dashboard_service import DashboardService
from core.security import get_current_user
from models import User

router = APIRouter(prefix="/api/dashboard", tags=["Dashboard"], redirect_slashes=False)


def get_dashboard_service(db: AsyncSession = Depends(get_db)) -> DashboardService:
    return DashboardService(db)


@router.get("", response_model=DashboardResponse)
@router.get("/", response_model=DashboardResponse)
async def get_dashboard(
    service: DashboardService = Depends(get_dashboard_service),
    current_user: User = Depends(get_current_user),
):
    """Lấy thống kê tổng quan cho người dùng — mở rộng với streak, xp, gems, level."""
    stats = await service.get_stats(user_id=current_user.id)
    return stats


@router.get("/user-stats", response_model=UserStatsResponse)
async def get_user_stats(
    service: DashboardService = Depends(get_dashboard_service),
    current_user: User = Depends(get_current_user),
):
    """Lấy thông tin header: streak, xp, gems, level."""
    stats = await service.get_user_stats(user_id=current_user.id)
    return stats


@router.get("/today-review", response_model=TodayReviewResponse)
async def get_today_review(
    service: DashboardService = Depends(get_dashboard_service),
    current_user: User = Depends(get_current_user),
):
    """Lấy danh sách từ vựng cần ôn tập hôm nay (Spaced Repetition)."""
    review = await service.get_today_review(user_id=current_user.id)
    return review


@router.get("/topic-progress", response_model=TopicProgressResponse)
async def get_topic_progress(
    service: DashboardService = Depends(get_dashboard_service),
    current_user: User = Depends(get_current_user),
):
    """Lấy tiến độ học tập theo từng chủ đề."""
    progress = await service.get_topic_progress(user_id=current_user.id)
    return progress


@router.get("/weekly-activity", response_model=WeeklyActivityResponse)
async def get_weekly_activity(
    service: DashboardService = Depends(get_dashboard_service),
    current_user: User = Depends(get_current_user),
):
    """Lấy hoạt động học tập 7 ngày gần nhất."""
    activity = await service.get_weekly_activity(user_id=current_user.id)
    return activity


@router.get("/skills", response_model=SkillsResponse)
async def get_skills(
    service: DashboardService = Depends(get_dashboard_service),
    current_user: User = Depends(get_current_user),
):
    """Lấy thống kê 4 kỹ năng: Nghe hiểu, Đọc hiểu, Từ vựng, Ngữ pháp."""
    skills = await service.get_skills(user_id=current_user.id)
    return skills
