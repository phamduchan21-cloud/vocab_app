import uuid

import pytest
from sqlalchemy import func, select

from database import async_session_factory, init_db
from models import RewardTransaction, User, UserReward, UserWallet
from services.gamification_service import GamificationService
from services.learning_path_service import LearningPathService


async def _create_user(session, *, english_level=None):
    user_id = str(uuid.uuid4())
    user = User(
        id=user_id,
        email=f"{user_id}@example.com",
        username="Profile Tester",
        english_level=english_level,
    )
    session.add(user)
    await session.commit()
    return user


@pytest.mark.asyncio
async def test_claim_reward_is_idempotent_and_updates_ledger_once():
    await init_db()
    async with async_session_factory() as session:
        user = await _create_user(session)
        reward = UserReward(
            id=str(uuid.uuid4()),
            user_id=user.id,
            reward_key=f"test_reward_{uuid.uuid4()}",
            source_type="achievement",
            title="Tem kiểm thử",
            xp_amount=120,
            gems_amount=12,
            status="pending",
        )
        session.add(reward)
        await session.commit()

        service = GamificationService(session)
        result = await service.claim_reward(user.id, reward.id)

        assert result.xp_earned == 120
        assert result.gems_earned == 12
        assert result.xp_total == 120
        assert result.gems_balance == 12

        with pytest.raises(ValueError, match="đã được nhận"):
            await service.claim_reward(user.id, reward.id)

        transaction_count = await session.scalar(
            select(func.count())
            .select_from(RewardTransaction)
            .where(RewardTransaction.user_id == user.id)
        )
        wallet = await session.get(UserWallet, user.id)
        assert transaction_count == 1
        assert wallet is not None
        assert wallet.gems_balance == 12


@pytest.mark.asyncio
async def test_new_user_starts_at_a1_and_placement_waives_prior_steps():
    await init_db()
    async with async_session_factory() as session:
        user = await _create_user(session)
        service = LearningPathService(session)

        initial = await service.get_path(user)
        assert initial.current_cefr == "A1"
        assert initial.steps[0].status == "current"

        placed = await service.place_user(user, "B1", "placement_test")
        statuses = {step.cefr_level: step.status for step in placed.steps}
        assert placed.current_cefr == "B1"
        assert placed.placement_source == "placement_test"
        assert statuses == {
            "A1": "waived",
            "A2": "waived",
            "B1": "current",
            "B2": "locked",
        }
        assert user.english_level == "intermediate"


@pytest.mark.asyncio
async def test_learning_step_cannot_complete_without_required_results():
    await init_db()
    async with async_session_factory() as session:
        user = await _create_user(session, english_level="beginner")
        service = LearningPathService(session)
        await service.get_path(user)

        with pytest.raises(ValueError):
            await service.complete_step(user, "A1")
