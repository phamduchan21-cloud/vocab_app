from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from database import get_db
from schemas import (
    RecordActivityRequest,
    RecordActivityResponse,
    AchievementResponse,
    LeaderboardResponse,
    ClaimStreakResponse,
    RewardItemResponse,
    RewardSummaryResponse,
    RewardClaimResponse,
    RewardTransactionResponse,
)
from services.gamification_service import GamificationService
from core.security import get_current_user
from models import User

router = APIRouter(prefix="/api/gamification", tags=["Gamification"], redirect_slashes=False)


def get_gamification_service(db: AsyncSession = Depends(get_db)) -> GamificationService:
    return GamificationService(db)


@router.post("/record-activity", response_model=RecordActivityResponse)
async def record_activity(
    data: RecordActivityRequest,
    service: GamificationService = Depends(get_gamification_service),
    current_user: User = Depends(get_current_user),
):
    """Ghi nhận hoạt động học tập và cập nhật XP/streak/achievements.

    - `activity_type`: learn | review | quiz | streak_claim
    - `xp_earned`: tự ghi nếu muốn override (mặc định: learn=5, review=3, quiz=10)
    """
    result = await service.record_activity(
        user_id=current_user.id,
        request=data,
    )
    return result


@router.get("/achievements", response_model=list[AchievementResponse])
async def get_achievements(
    service: GamificationService = Depends(get_gamification_service),
    current_user: User = Depends(get_current_user),
):
    """Lấy danh sách thành tựu đã đạt được."""
    achievements = await service.get_achievements(user_id=current_user.id)
    return achievements


@router.get("/leaderboard", response_model=LeaderboardResponse)
async def get_leaderboard(
    service: GamificationService = Depends(get_gamification_service),
    current_user: User = Depends(get_current_user),
):
    """Lấy bảng xếp hạng users theo tổng XP."""
    leaderboard = await service.get_leaderboard(user_id=current_user.id)
    return leaderboard


@router.post("/claim-streak-reward", response_model=ClaimStreakResponse)
async def claim_streak_reward(
    service: GamificationService = Depends(get_gamification_service),
    current_user: User = Depends(get_current_user),
):
    """Nhận thưởng streak milestone (7, 14, 30, 60, 100 ngày)."""
    result = await service.claim_streak_reward(user_id=current_user.id)
    if result is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Không thể nhận thưởng lúc này.",
        )
    return result


@router.get("/rewards/summary", response_model=RewardSummaryResponse)
async def get_reward_summary(
    service: GamificationService = Depends(get_gamification_service),
    current_user: User = Depends(get_current_user),
):
    return await service.get_reward_summary(user_id=current_user.id)


@router.get("/rewards", response_model=list[RewardItemResponse])
async def get_rewards(
    status_filter: str | None = None,
    service: GamificationService = Depends(get_gamification_service),
    current_user: User = Depends(get_current_user),
):
    if status_filter not in {None, "pending", "claimed", "expired"}:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Trạng thái phần thưởng không hợp lệ.",
        )
    return await service.get_rewards(
        user_id=current_user.id,
        status_filter=status_filter,
    )


@router.get(
    "/rewards/transactions",
    response_model=list[RewardTransactionResponse],
)
async def get_reward_history(
    service: GamificationService = Depends(get_gamification_service),
    current_user: User = Depends(get_current_user),
):
    return await service.get_reward_history(user_id=current_user.id)


@router.post("/rewards/claim-all", response_model=RewardClaimResponse)
async def claim_all_rewards(
    service: GamificationService = Depends(get_gamification_service),
    current_user: User = Depends(get_current_user),
):
    return await service.claim_all_rewards(user_id=current_user.id)


@router.post("/rewards/{reward_id}/claim", response_model=RewardClaimResponse)
async def claim_reward(
    reward_id: str,
    service: GamificationService = Depends(get_gamification_service),
    current_user: User = Depends(get_current_user),
):
    try:
        return await service.claim_reward(
            user_id=current_user.id,
            reward_id=reward_id,
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=str(exc),
        ) from exc
