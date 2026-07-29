import uuid
from datetime import date, datetime, timedelta, timezone
from typing import List, Optional

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, text

from models import (
    MockTest,
    QuizResult,
    UserDailyActivity,
    UserAchievement,
    User,
    UserReward,
    UserWallet,
    RewardTransaction,
    Vocabulary,
)
from schemas import (
    RecordActivityRequest,
    RecordActivityResponse,
    AchievementResponse,
    LeaderboardEntry,
    LeaderboardResponse,
    ClaimStreakResponse,
    RewardItemResponse,
    RewardSummaryResponse,
    RewardClaimResponse,
    RewardTransactionResponse,
)
from services.dashboard_service import calc_level

# ─── Config ────────────────────────────────────────────────────────────

STREAK_MILESTONES = {
    7: {"key": "streak_7", "title": "🔥 7 Ngày Liên Tiếp", "gems": 50, "xp": 200},
    14: {"key": "streak_14", "title": "🔥 14 Ngày Liên Tiếp", "gems": 100, "xp": 300},
    30: {"key": "streak_30", "title": "🏅 30 Ngày Kiên Trì", "gems": 200, "xp": 500},
    60: {"key": "streak_60", "title": "💪 60 Ngày Bền Bỉ", "gems": 300, "xp": 800},
    100: {"key": "streak_100", "title": "👑 100 Ngày Huyền Thoại", "gems": 500, "xp": 1000},
}

# XP reward cho các hoạt động
XP_REWARDS = {
    "learn": 5,     # Học từ mới
    "review": 3,    # Ôn tập 1 từ
    "quiz": 10,     # Làm quiz
}

# Achievement khác (không streak)
OTHER_ACHIEVEMENTS = {
    "first_word": {"title": "🌱 Bắt Đầu", "desc": "Thêm từ vựng đầu tiên", "icon": "seedling"},
    "word_50": {"title": "📚 50 Từ Vựng", "desc": "Đã thêm 50 từ", "icon": "books"},
    "word_100": {"title": "📖 100 Từ Vựng", "desc": "Đã học 100 từ", "icon": "dictionary"},
    "word_500": {"title": "📮 500 Từ Vựng", "desc": "Đã học 500 từ", "icon": "postbox"},
    "word_1000": {"title": "🗺️ 1000 Từ Vựng", "desc": "Đã học 1000 từ", "icon": "map"},
    "perfect_quiz": {"title": "🎯 Hoàn Hảo", "desc": "Quiz đạt 100%", "icon": "star"},
    "perfect_mini_test": {"title": "💌 Bưu Kiện Hoàn Hảo", "desc": "Mini Test đạt 100%", "icon": "letter"},
    "quiz_10": {"title": "🎮 10 Quiz", "desc": "Đã làm 10 bài quiz", "icon": "gamepad"},
    "night_owl": {"title": "🦉 Cú Đêm", "desc": "Học sau 10 giờ tối", "icon": "moon"},
}


class GamificationService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def record_activity(
        self,
        user_id: str,
        request: RecordActivityRequest,
    ) -> RecordActivityResponse:
        """Ghi nhận hoạt động học tập — cập nhật XP, streak, gems, achievements."""
        today = date.today()
        activity_type = request.activity_type
        xp_amount = request.xp_earned or XP_REWARDS.get(activity_type, 0)

        # ── 1. Upsert UserDailyActivity cho hôm nay ────────────────
        today_activity = await self._get_or_create_today_activity(user_id, today)

        # Cập nhật số liệu theo loại activity
        if activity_type == "learn":
            today_activity.vocab_learned = (today_activity.vocab_learned or 0) + 1
        elif activity_type == "review":
            today_activity.vocab_reviewed = (today_activity.vocab_reviewed or 0) + 1
        elif activity_type == "quiz":
            today_activity.quiz_done = (today_activity.quiz_done or 0) + 1

        today_activity.xp_earned = (today_activity.xp_earned or 0) + xp_amount
        await self.db.commit()

        # ── 2. Tính tổng XP và streak ──────────────────────────────
        total_xp_query = select(func.coalesce(func.sum(UserDailyActivity.xp_earned), 0)).where(
            UserDailyActivity.user_id == user_id,
        )
        total_xp = await self.db.scalar(total_xp_query) or 0

        streak = await self._calc_streak_for_user(user_id, today)

        # ── 3. Tính level ──────────────────────────────────────────
        level, level_title = calc_level(total_xp)

        # ── 4. Gems (tổng) ─────────────────────────────────────────
        wallet = await self._get_or_create_wallet(user_id)
        total_gems = wallet.gems_balance or 0

        # Gems earned hôm nay
        gems_earned = xp_amount // 10 if xp_amount > 0 else 0
        if gems_earned:
            await self._add_wallet_transaction(
                user_id=user_id,
                transaction_key=f"activity:{uuid.uuid4()}",
                source_type="activity",
                source_id=str(today_activity.id),
                gems_delta=gems_earned,
                description=f"Thưởng hoạt động {activity_type}",
                wallet=wallet,
            )
            await self.db.commit()

        # ── 5. Check achievements ──────────────────────────────────
        new_achievements = await self._check_achievements(user_id, streak)

        return RecordActivityResponse(
            xp_total=total_xp,
            streak=streak,
            current_level=level,
            level_title=level_title,
            gems_earned=gems_earned,
            gems_total=total_gems,
            new_achievements=[a.model_dump() for a in new_achievements],
        )

    async def get_achievements(self, user_id: str) -> List[AchievementResponse]:
        """Lấy danh sách thành tựu đã đạt được."""
        query = select(UserAchievement).where(
            UserAchievement.user_id == user_id
        ).order_by(UserAchievement.unlocked_at.desc())
        result = await self.db.execute(query)
        items = list(result.scalars().all())

        return [
            AchievementResponse(
                id=str(a.id),
                achievement_key=a.achievement_key,
                title=a.title,
                description=a.description,
                icon=a.icon,
                unlocked_at=a.unlocked_at,
            )
            for a in items
        ]

    async def get_leaderboard(self, user_id: str, limit: int = 10) -> LeaderboardResponse:
        """Bảng xếp hạng — top users theo tổng XP."""
        # Aggregate XP per user
        subquery = (
            select(
                UserDailyActivity.user_id,
                func.sum(UserDailyActivity.xp_earned).label("total_xp"),
            )
            .group_by(UserDailyActivity.user_id)
            .subquery()
        )

        # Join với users để lấy username
        query = (
            select(
                User.id,
                User.username,
                subquery.c.total_xp,
            )
            .join(subquery, User.id == subquery.c.user_id)
            .order_by(subquery.c.total_xp.desc())
            .limit(limit)
        )
        result = await self.db.execute(query)
        rows = result.fetchall()

        entries = []
        for rank, (uid, username, xp) in enumerate(rows, 1):
            # Tính streak cho mỗi user
            s = await self._calc_streak_for_user(uid, date.today())
            entries.append(LeaderboardEntry(
                rank=rank,
                user_id=uid,
                username=username or uid[:8],
                xp=xp or 0,
                streak=s,
            ))

        return LeaderboardResponse(entries=entries)

    async def claim_streak_reward(self, user_id: str) -> Optional[ClaimStreakResponse]:
        """Compatibility endpoint backed by the reward inbox."""
        streak = await self._calc_streak_for_user(user_id, date.today())
        await self._check_achievements(user_id, streak)
        pending = await self.db.scalar(
            select(UserReward)
            .where(
                UserReward.user_id == user_id,
                UserReward.status == "pending",
                UserReward.reward_key.like("streak_%"),
            )
            .order_by(UserReward.unlocked_at.desc())
        )
        if pending is None:
            return ClaimStreakResponse(
                streak=streak,
                reward_gems=0,
                reward_xp=0,
                message=f"Streak hiện tại là {streak} ngày. Chưa có quà mới để nhận.",
                new_achievement=None,
            )
        claim = await self.claim_reward(user_id, pending.id)
        return ClaimStreakResponse(
            streak=streak,
            reward_gems=claim.gems_earned,
            reward_xp=claim.xp_earned,
            message=claim.message,
            new_achievement=None,
        )

    async def get_reward_summary(self, user_id: str) -> RewardSummaryResponse:
        streak = await self._calc_streak_for_user(user_id, date.today())
        await self._check_achievements(user_id, streak)
        claimable = await self.db.scalar(
            select(func.count())
            .select_from(UserReward)
            .where(UserReward.user_id == user_id, UserReward.status == "pending")
        ) or 0
        wallet = await self._get_or_create_wallet(user_id)
        next_streak = next(
            (value for value in sorted(STREAK_MILESTONES) if value > streak),
            None,
        )
        return RewardSummaryResponse(
            claimable_count=claimable,
            xp_total=await self._get_total_xp(user_id),
            gems_balance=wallet.gems_balance or 0,
            next_streak=next_streak,
            streak_progress=streak,
        )

    async def get_rewards(
        self,
        user_id: str,
        status_filter: Optional[str] = None,
    ) -> List[RewardItemResponse]:
        await self.get_reward_summary(user_id)
        query = select(UserReward).where(UserReward.user_id == user_id)
        if status_filter:
            query = query.where(UserReward.status == status_filter)
        result = await self.db.execute(
            query.order_by(UserReward.unlocked_at.desc()).limit(100)
        )
        return [RewardItemResponse.model_validate(item) for item in result.scalars()]

    async def get_reward_history(
        self,
        user_id: str,
    ) -> List[RewardTransactionResponse]:
        result = await self.db.execute(
            select(RewardTransaction)
            .where(RewardTransaction.user_id == user_id)
            .order_by(RewardTransaction.created_at.desc())
            .limit(50)
        )
        return [
            RewardTransactionResponse.model_validate(item)
            for item in result.scalars()
        ]

    async def claim_reward(
        self,
        user_id: str,
        reward_id: str,
    ) -> RewardClaimResponse:
        reward = await self.db.scalar(
            select(UserReward)
            .where(UserReward.id == reward_id, UserReward.user_id == user_id)
            .with_for_update()
        )
        if reward is None:
            raise ValueError("Phần thưởng không tồn tại.")
        if reward.status != "pending":
            raise ValueError("Phần thưởng này đã được nhận.")
        return await self._claim_rewards(user_id, [reward])

    async def claim_all_rewards(self, user_id: str) -> RewardClaimResponse:
        result = await self.db.execute(
            select(UserReward)
            .where(UserReward.user_id == user_id, UserReward.status == "pending")
            .order_by(UserReward.unlocked_at)
            .with_for_update()
        )
        rewards = list(result.scalars().all())
        if not rewards:
            wallet = await self._get_or_create_wallet(user_id)
            return RewardClaimResponse(
                claimed=[],
                xp_total=await self._get_total_xp(user_id),
                gems_balance=wallet.gems_balance or 0,
                message="Bạn chưa có phần thưởng nào đang chờ.",
            )
        return await self._claim_rewards(user_id, rewards)

    async def _claim_rewards(
        self,
        user_id: str,
        rewards: List[UserReward],
    ) -> RewardClaimResponse:
        xp_earned = sum(item.xp_amount or 0 for item in rewards)
        gems_earned = sum(item.gems_amount or 0 for item in rewards)
        today_activity = await self._get_or_create_today_activity(user_id, date.today())
        today_activity.xp_earned = (today_activity.xp_earned or 0) + xp_earned
        wallet = await self._get_or_create_wallet(user_id)
        now = datetime.now(timezone.utc)

        for reward in rewards:
            reward.status = "claimed"
            reward.claimed_at = now
            await self._add_wallet_transaction(
                user_id=user_id,
                transaction_key=f"reward:{reward.id}",
                source_type="reward",
                source_id=reward.id,
                xp_delta=reward.xp_amount or 0,
                gems_delta=reward.gems_amount or 0,
                description=reward.title,
                wallet=wallet,
            )
        await self.db.commit()
        return RewardClaimResponse(
            claimed=[RewardItemResponse.model_validate(item) for item in rewards],
            xp_earned=xp_earned,
            gems_earned=gems_earned,
            xp_total=await self._get_total_xp(user_id),
            gems_balance=wallet.gems_balance or 0,
            message=f"Đã nhận {xp_earned} XP và {gems_earned} gems.",
        )

    # ─── Private helpers ───────────────────────────────────────────────

    async def _calc_streak_for_user(self, user_id: str, today: date) -> int:
        """Tính streak cho user cụ thể."""
        activity_dates_query = (
            select(UserDailyActivity.activity_date)
            .where(
                UserDailyActivity.user_id == user_id,
                UserDailyActivity.activity_date <= today,
            )
            .order_by(UserDailyActivity.activity_date.desc())
        )
        result = await self.db.execute(activity_dates_query)
        dates = [row[0] for row in result.fetchall()]

        if not dates:
            return 0

        streak = 0
        check_date = today

        # Nếu hôm nay chưa học, kiểm tra hôm qua
        if dates[0] != today and dates[0] != today - timedelta(days=1):
            return 0  # Không có hoạt động hôm nay hoặc hôm qua

        for d in dates:
            if d == check_date:
                streak += 1
                check_date -= timedelta(days=1)
            elif d < check_date:
                break

        return streak

    async def _get_total_xp(self, user_id: str) -> int:
        query = select(func.coalesce(func.sum(UserDailyActivity.xp_earned), 0)).where(
            UserDailyActivity.user_id == user_id,
        )
        return await self.db.scalar(query) or 0

    async def _get_or_create_wallet(self, user_id: str) -> UserWallet:
        wallet = await self.db.get(UserWallet, user_id)
        if wallet is not None:
            return wallet
        await self.db.execute(
            text(
                """
                INSERT INTO user_wallets (user_id, gems_balance)
                VALUES (:user_id, 0)
                ON CONFLICT (user_id) DO NOTHING
                """
            ),
            {"user_id": user_id},
        )
        await self.db.flush()
        wallet = await self.db.get(UserWallet, user_id)
        if wallet is None:
            raise RuntimeError("Không thể khởi tạo ví phần thưởng.")
        return wallet

    async def _add_wallet_transaction(
        self,
        *,
        user_id: str,
        transaction_key: str,
        source_type: str,
        source_id: Optional[str] = None,
        xp_delta: int = 0,
        gems_delta: int = 0,
        description: Optional[str] = None,
        wallet: Optional[UserWallet] = None,
    ) -> RewardTransaction:
        existing = await self.db.scalar(
            select(RewardTransaction).where(
                RewardTransaction.user_id == user_id,
                RewardTransaction.transaction_key == transaction_key,
            )
        )
        if existing is not None:
            return existing
        target_wallet = wallet or await self._get_or_create_wallet(user_id)
        target_wallet.gems_balance = (target_wallet.gems_balance or 0) + gems_delta
        transaction = RewardTransaction(
            id=str(uuid.uuid4()),
            user_id=user_id,
            transaction_key=transaction_key,
            source_type=source_type,
            source_id=source_id,
            xp_delta=xp_delta,
            gems_delta=gems_delta,
            description=description,
        )
        self.db.add(transaction)
        return transaction

    async def _ensure_reward_for_achievement(
        self,
        achievement: UserAchievement,
        *,
        xp_amount: int,
        gems_amount: int,
    ) -> UserReward:
        existing = await self.db.scalar(
            select(UserReward).where(
                UserReward.user_id == achievement.user_id,
                UserReward.reward_key == achievement.achievement_key,
            )
        )
        if existing is not None:
            return existing
        reward = UserReward(
            id=str(uuid.uuid4()),
            user_id=achievement.user_id,
            reward_key=achievement.achievement_key,
            source_type="achievement",
            title=achievement.title,
            description=achievement.description,
            xp_amount=xp_amount,
            gems_amount=gems_amount,
            status="pending",
            unlocked_at=achievement.unlocked_at or datetime.utcnow(),
        )
        self.db.add(reward)
        await self.db.commit()
        await self.db.refresh(reward)
        return reward

    async def _get_or_create_today_activity(self, user_id: str, today: date) -> UserDailyActivity:
        """Tìm activity hôm nay, nếu chưa có thì tạo mới."""
        query = select(UserDailyActivity).where(
            UserDailyActivity.user_id == user_id,
            UserDailyActivity.activity_date == today,
        )
        result = await self.db.execute(query)
        activity = result.scalar_one_or_none()

        if not activity:
            activity = UserDailyActivity(
                id=str(uuid.uuid4()),
                user_id=user_id,
                activity_date=today,
                xp_earned=0,
                vocab_learned=0,
                vocab_reviewed=0,
                quiz_done=0,
            )
            self.db.add(activity)
            await self.db.commit()
            await self.db.refresh(activity)

        return activity

    async def _has_achievement(self, user_id: str, key: str) -> bool:
        """Kiểm tra user đã có achievement này chưa."""
        query = select(UserAchievement).where(
            UserAchievement.user_id == user_id,
            UserAchievement.achievement_key == key,
        )
        result = await self.db.execute(query)
        return result.scalar_one_or_none() is not None

    async def _check_achievements(self, user_id: str, streak: int) -> List[AchievementResponse]:
        """Kiểm tra và mở khoá achievement mới. Trả về danh sách achievements mới."""
        new_ones = []

        # Kiểm tra streak milestones
        for s, milestone in sorted(STREAK_MILESTONES.items()):
            if streak >= s:
                if not await self._has_achievement(user_id, milestone["key"]):
                    ach = UserAchievement(
                        id=str(uuid.uuid4()),
                        user_id=user_id,
                        achievement_key=milestone["key"],
                        title=milestone["title"],
                        description=f"Đạt streak {s} ngày",
                        icon="fire",
                    )
                    self.db.add(ach)
                    await self.db.commit()
                    await self.db.refresh(ach)
                    await self._ensure_reward_for_achievement(
                        ach,
                        xp_amount=milestone["xp"],
                        gems_amount=milestone["gems"],
                    )
                    new_ones.append(AchievementResponse(
                        id=str(ach.id),
                        achievement_key=ach.achievement_key,
                        title=ach.title,
                        description=ach.description,
                        icon=ach.icon,
                        unlocked_at=ach.unlocked_at,
                    ))

        # Kiểm tra word count achievements
        vocab_count_query = select(func.count()).select_from(Vocabulary).where(Vocabulary.user_id == user_id)
        vocab_count = await self.db.scalar(vocab_count_query) or 0

        word_milestones = [
            (1, "first_word"),
            (50, "word_50"),
            (100, "word_100"),
            (500, "word_500"),
            (1000, "word_1000"),
        ]
        for count, key in word_milestones:
            if vocab_count >= count and not await self._has_achievement(user_id, key):
                info = OTHER_ACHIEVEMENTS[key]
                ach = UserAchievement(
                    id=str(uuid.uuid4()),
                    user_id=user_id,
                    achievement_key=key,
                    title=info["title"],
                    description=info["desc"],
                    icon=info["icon"],
                )
                self.db.add(ach)
                await self.db.commit()
                await self.db.refresh(ach)
                await self._ensure_reward_for_achievement(
                    ach,
                    xp_amount=50 if count < 500 else 150,
                    gems_amount=5 if count < 500 else 15,
                )
                new_ones.append(AchievementResponse(
                    id=str(ach.id),
                    achievement_key=ach.achievement_key,
                    title=ach.title,
                    description=ach.description,
                    icon=ach.icon,
                    unlocked_at=ach.unlocked_at,
                ))

        quiz_count = await self.db.scalar(
            select(func.count()).select_from(QuizResult).where(
                QuizResult.user_id == user_id
            )
        ) or 0
        mock_test_count = await self.db.scalar(
            select(func.count()).select_from(MockTest).where(
                MockTest.user_id == user_id
            )
        ) or 0
        perfect_quiz = await self.db.scalar(
            select(func.count()).select_from(QuizResult).where(
                QuizResult.user_id == user_id,
                QuizResult.score_percent >= 100,
            )
        ) or 0
        perfect_mini_test = await self.db.scalar(
            select(func.count()).select_from(MockTest).where(
                MockTest.user_id == user_id,
                MockTest.score_percent >= 100,
            )
        ) or 0
        other_checks = [
            (quiz_count + mock_test_count >= 10, "quiz_10"),
            (perfect_quiz > 0, "perfect_quiz"),
            (perfect_mini_test > 0, "perfect_mini_test"),
            (datetime.now().hour >= 22, "night_owl"),
        ]
        for achieved, key in other_checks:
            if not achieved or await self._has_achievement(user_id, key):
                continue
            info = OTHER_ACHIEVEMENTS[key]
            achievement = UserAchievement(
                id=str(uuid.uuid4()),
                user_id=user_id,
                achievement_key=key,
                title=info["title"],
                description=info["desc"],
                icon=info["icon"],
            )
            self.db.add(achievement)
            await self.db.commit()
            await self.db.refresh(achievement)
            await self._ensure_reward_for_achievement(
                achievement,
                xp_amount=75,
                gems_amount=8,
            )
            new_ones.append(AchievementResponse(
                id=str(achievement.id),
                achievement_key=achievement.achievement_key,
                title=achievement.title,
                description=achievement.description,
                icon=achievement.icon,
                unlocked_at=achievement.unlocked_at,
            ))

        return new_ones
