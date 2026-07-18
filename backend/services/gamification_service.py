import uuid
from datetime import date, datetime, timedelta
from typing import List, Optional

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_

from models import (
    MockTest,
    QuizResult,
    UserDailyActivity,
    UserAchievement,
    User,
    Vocabulary,
)
from schemas import (
    RecordActivityRequest,
    RecordActivityResponse,
    AchievementResponse,
    LeaderboardEntry,
    LeaderboardResponse,
    ClaimStreakResponse,
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
        total_gems = total_xp // 10

        # Gems earned hôm nay
        gems_earned = xp_amount // 10 if xp_amount > 0 else 0

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
        """Claim reward khi đạt milestone streak."""
        streak = await self._calc_streak_for_user(user_id, date.today())

        # Tìm milestone gần nhất có thể claim
        milestone = None
        milestone_streak = 0
        for s, m in sorted(STREAK_MILESTONES.items(), reverse=True):
            if streak >= s:
                # Kiểm tra đã claim chưa
                existing = await self._has_achievement(user_id, m["key"])
                if not existing:
                    milestone = m
                    milestone_streak = s
                    break

        if not milestone:
            # Kiểm tra có milestone nào chưa claim không
            # Nếu không, trả về streak hiện tại
            total_gems = (await self._get_total_xp(user_id)) // 10
            return ClaimStreakResponse(
                streak=streak,
                reward_gems=0,
                reward_xp=0,
                message=f"Bạn đã đạt streak {streak} ngày! Hãy cố gắng thêm để nhận thưởng.",
                new_achievement=None,
            )

        # Tạo achievement
        achievement = UserAchievement(
            id=str(uuid.uuid4()),
            user_id=user_id,
            achievement_key=milestone["key"],
            title=milestone["title"],
            description=f"Đạt streak {milestone_streak} ngày",
            icon="fire",
        )
        self.db.add(achievement)

        # Cộng XP + gems vào daily activity
        today = date.today()
        today_activity = await self._get_or_create_today_activity(user_id, today)
        today_activity.xp_earned = (today_activity.xp_earned or 0) + milestone["xp"]
        await self.db.commit()

        return ClaimStreakResponse(
            streak=streak,
            reward_gems=milestone["gems"],
            reward_xp=milestone["xp"],
            message=f"🎉 Chúc mừng! Bạn đã nhận thưởng streak {milestone_streak} ngày! +{milestone['xp']}XP +{milestone['gems']} Gems",
            new_achievement=AchievementResponse(
                id=str(achievement.id),
                achievement_key=achievement.achievement_key,
                title=achievement.title,
                description=achievement.description,
                icon=achievement.icon,
                unlocked_at=achievement.unlocked_at,
            ),
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
            new_ones.append(AchievementResponse(
                id=str(achievement.id),
                achievement_key=achievement.achievement_key,
                title=achievement.title,
                description=achievement.description,
                icon=achievement.icon,
                unlocked_at=achievement.unlocked_at,
            ))

        return new_ones
