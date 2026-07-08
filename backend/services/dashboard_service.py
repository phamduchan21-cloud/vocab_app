from datetime import date, timedelta, datetime
from typing import List, Optional, Tuple

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_

from models import Vocabulary, QuizResult, UserDailyActivity, UserAchievement
from schemas import (
    DashboardResponse,
    DashboardStatsVocab,
    DashboardStatsQuiz,
    TodayReviewItem,
    TodayReviewResponse,
    TopicProgressItem,
    TopicProgressResponse,
    WeeklyActivityDay,
    WeeklyActivityResponse,
    UserStatsResponse,
    SkillItem,
    SkillsResponse,
)

# ─── Level Config ─────────────────────────────────────────────────────
LEVEL_THRESHOLDS = [
    (0, "🌱 Mầm non"),
    (500, "🌿 Lá xanh"),
    (1500, "🌳 Cây lớn"),
    (4000, "🏔️ Cao thủ"),
    (8000, "🦅 Phiêu lưu"),
    (15000, "👑 Huyền thoại"),
]

WEEKLY_XP_GOAL = 500  # Mục tiêu XP mỗi tuần


def calc_level(total_xp: int) -> Tuple[int, str]:
    """Tính level và danh hiệu dựa trên tổng XP."""
    level = 1
    title = LEVEL_THRESHOLDS[0][1]
    for threshold, t in reversed(LEVEL_THRESHOLDS):
        if total_xp >= threshold:
            level = LEVEL_THRESHOLDS.index((threshold, t)) + 1
            title = t
            break
    return level, title


class DashboardService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def _get_quiz_aggregates(self, user_id: str):
        """Single query: count, sum correct, sum total from QuizResult."""
        row = await self.db.execute(
            select(
                func.count().label("count"),
                func.coalesce(func.sum(QuizResult.correct_answers), 0).label("correct"),
                func.coalesce(func.sum(QuizResult.total_questions), 0).label("total"),
            ).where(QuizResult.user_id == user_id)
        )
        r = row.one()
        return r.count, r.correct, r.total

    async def _get_xp_total(self, user_id: str) -> int:
        return await self.db.scalar(
            select(func.coalesce(func.sum(UserDailyActivity.xp_earned), 0))
            .where(UserDailyActivity.user_id == user_id)
        ) or 0

    async def get_stats(self, user_id: str) -> DashboardResponse:
        """Get expanded dashboard statistics."""
        vocab_count = await self.db.scalar(
            select(func.count()).select_from(Vocabulary).where(Vocabulary.user_id == user_id)
        ) or 0

        quiz_count, correct_answers, total_questions = await self._get_quiz_aggregates(user_id)
        accuracy_rate = round((correct_answers / total_questions) * 100, 2) if total_questions > 0 else 0.0

        total_xp = await self._get_xp_total(user_id)
        gems = total_xp // 10
        level, level_title = calc_level(total_xp)
        streak = await self._calc_streak(user_id)
        weekly_progress = await self._calc_weekly_progress(user_id)

        recent_vocabs = await self._get_recent_vocabs(user_id, limit=5)
        recent_quizzes = await self._get_recent_quizzes(user_id, limit=5)

        return DashboardResponse(
            streak=streak, xp=total_xp, gems=gems,
            level=level, level_title=level_title,
            weekly_progress=weekly_progress,
            vocab_count=vocab_count, quiz_count=quiz_count,
            correct_answers=correct_answers, accuracy_rate=accuracy_rate,
            recent_vocabs=recent_vocabs, recent_quizzes=recent_quizzes,
        )

    async def get_user_stats(self, user_id: str) -> UserStatsResponse:
        """Header stats — uses same aggregates."""
        vocab_count = await self.db.scalar(
            select(func.count()).select_from(Vocabulary).where(Vocabulary.user_id == user_id)
        ) or 0
        quiz_count, correct_answers, total_questions = await self._get_quiz_aggregates(user_id)
        accuracy_rate = round((correct_answers / total_questions) * 100, 2) if total_questions > 0 else 0.0

        total_xp = await self._get_xp_total(user_id)
        gems = total_xp // 10
        level, level_title = calc_level(total_xp)
        streak = await self._calc_streak(user_id)
        weekly_progress = await self._calc_weekly_progress(user_id)

        return UserStatsResponse(
            streak=streak, xp=total_xp, gems=gems,
            level=level, level_title=level_title,
            weekly_progress=weekly_progress,
            vocab_count=vocab_count, quiz_count=quiz_count,
            correct_answers=correct_answers, accuracy_rate=accuracy_rate,
        )

    # ─── Today Review ──────────────────────────────────────────────────

    async def get_today_review(self, user_id: str) -> TodayReviewResponse:
        """Lấy danh sách từ cần ôn tập hôm nay (next_review_date <= today hoặc chưa review lần nào)."""
        today = date.today()

        # Từ đến hạn ôn: next_review_date <= today
        due_query = select(Vocabulary).where(
            Vocabulary.user_id == user_id,
            Vocabulary.next_review_date <= today,
        )
        due_result = await self.db.execute(due_query)
        due_words = list(due_result.scalars().all())

        # Từ mới chưa review lần nào: review_count == 0 và next_review_date IS NULL
        new_query = select(Vocabulary).where(
            Vocabulary.user_id == user_id,
            Vocabulary.review_count == 0,
            Vocabulary.next_review_date.is_(None),
        )
        new_result = await self.db.execute(new_query)
        new_words = list(new_result.scalars().all())

        # Gộp + giới hạn 20 từ
        all_words = due_words + new_words
        all_words = all_words[:20]

        # Đã review bao nhiêu từ hôm nay
        completed_query = (
            select(func.count())
            .select_from(Vocabulary)
            .where(
                Vocabulary.user_id == user_id,
                Vocabulary.next_review_date <= today,
                Vocabulary.review_count > 0,
            )
        )
        completed_count = await self.db.scalar(completed_query) or 0

        total_due = len([w for w in due_words if w.review_count > 0])
        completed = min(completed_count, total_due)

        items = [
            TodayReviewItem(
                id=str(v.id),
                word=v.word,
                meaning=v.meaning,
                example=v.example,
                topic=v.topic,
                review_count=v.review_count or 0,
                ease_factor=v.ease_factor or 2.5,
                created_at=v.created_at,
            )
            for v in all_words
        ]

        return TodayReviewResponse(
            total=len(all_words),
            completed=completed,
            words=items,
        )

    # ─── Topic Progress ────────────────────────────────────────────────

    async def get_topic_progress(self, user_id: str) -> TopicProgressResponse:
        """Thống kê tiến độ theo từng chủ đề — 1 query, tính mastered in-memory."""
        query = select(Vocabulary).where(Vocabulary.user_id == user_id)
        result = await self.db.execute(query)
        all_vocabs = list(result.scalars().all())

        # Nhóm theo topic — tính luôn mastered trong 1 pass
        topic_map: dict = {}
        for v in all_vocabs:
            topic = v.topic or "general"
            if topic not in topic_map:
                topic_map[topic] = {"total": 0, "correct": 0, "wrong": 0, "mastered": 0}
            t = topic_map[topic]
            t["total"] += 1
            t["correct"] += v.times_correct or 0
            t["wrong"] += v.times_wrong or 0
            if v.review_count is not None and v.review_count >= 3 and (v.times_correct or 0) > (v.times_wrong or 0):
                t["mastered"] += 1

        topics = []
        for topic, stats in topic_map.items():
            total_attempts = stats["correct"] + stats["wrong"]
            accuracy = round((stats["correct"] / total_attempts) * 100, 1) if total_attempts > 0 else 0.0
            topics.append(TopicProgressItem(
                topic=topic, total=stats["total"],
                mastered=stats["mastered"], accuracy=accuracy,
            ))

        topics.sort(key=lambda t: t.total, reverse=True)
        return TopicProgressResponse(topics=topics)

    # ─── Weekly Activity ───────────────────────────────────────────────

    async def get_weekly_activity(self, user_id: str) -> WeeklyActivityResponse:
        """Lấy hoạt động 7 ngày gần nhất — 1 range query thay vì 7 queries."""
        today = date.today()
        week_ago = today - timedelta(days=6)

        rows = await self.db.execute(
            select(UserDailyActivity).where(
                UserDailyActivity.user_id == user_id,
                UserDailyActivity.activity_date >= week_ago,
                UserDailyActivity.activity_date <= today,
            )
        )
        activity_map = {r.activity_date: r for r in rows.scalars().all()}

        days = []
        for i in range(6, -1, -1):
            d = today - timedelta(days=i)
            a = activity_map.get(d)
            days.append(WeeklyActivityDay(
                date=d.isoformat(),
                xp=a.xp_earned or 0 if a else 0,
                quizzes=a.quiz_done or 0 if a else 0,
                learned=((a.vocab_learned or 0) + (a.vocab_reviewed or 0)) if a else 0,
            ))
        return WeeklyActivityResponse(days=days)

    # ─── Skills (Migii TOPIK inspired) ──────────────────────────────────

    async def get_skills(self, user_id: str) -> SkillsResponse:
        """Thống kê 4 kỹ năng: Nghe hiểu, Đọc hiểu, Từ vựng, Ngữ pháp.

        Dùng 1 query GROUP BY thay vì 12 queries riêng lẻ.
        """
        rows = await self.db.execute(
            select(
                QuizResult.quiz_type,
                func.count().label("total"),
                func.coalesce(func.sum(QuizResult.correct_answers), 0).label("correct"),
                func.coalesce(func.sum(QuizResult.total_questions), 0).label("total_q"),
            ).where(QuizResult.user_id == user_id)
             .group_by(QuizResult.quiz_type)
        )
        agg = {r.quiz_type: r for r in rows.fetchall()}

        skill_defs = [
            ("listening", "Nghe hiểu"),
            ("reading", "Đọc hiểu"),
            ("vocabulary", "Từ vựng"),
            ("grammar", "Ngữ pháp"),
        ]
        skills = []
        for qt, title in skill_defs:
            r = agg.get(qt)
            total = r.total if r else 0
            correct = r.correct if r else 0
            total_q = r.total_q if r else 0
            accuracy = round((correct / total_q) * 100, 1) if total_q > 0 else 0.0
            skills.append(SkillItem(
                type=qt, title=title, accuracy=accuracy,
                xp=correct * 10, completed=total, total=max(total, 1),
            ))
        return SkillsResponse(skills=skills)

    # ─── Private helpers ───────────────────────────────────────────────

    async def _calc_streak(self, user_id: str) -> int:
        """Tính streak: số ngày gần nhất có activity liên tục."""
        today = date.today()
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

        # Đếm streak lùi từ hôm nay
        streak = 0
        check_date = today

        # Hôm nay chưa học? Có thể vẫn còn streak nếu hôm qua có học
        # Kiểm tra xem hôm nay hoặc hôm qua có activity không
        if dates[0] == today or dates[0] == today - timedelta(days=1):
            for d in dates:
                if d == check_date:
                    streak += 1
                    check_date -= timedelta(days=1)
                elif d < check_date:
                    break

        return streak

    async def _calc_weekly_progress(self, user_id: str) -> int:
        """Tính % hoàn thành mục tiêu XP tuần này."""
        today = date.today()
        # Tìm thứ 2 tuần này
        days_since_monday = today.weekday()  # 0 = Monday
        monday = today - timedelta(days=days_since_monday)

        xp_week_query = (
            select(func.coalesce(func.sum(UserDailyActivity.xp_earned), 0))
            .where(
                UserDailyActivity.user_id == user_id,
                UserDailyActivity.activity_date >= monday,
                UserDailyActivity.activity_date <= today,
            )
        )
        xp_week = await self.db.scalar(xp_week_query) or 0

        progress = min(100, int((xp_week / WEEKLY_XP_GOAL) * 100))
        return progress

    async def _get_recent_vocabs(self, user_id: str, limit: int = 5) -> List[DashboardStatsVocab]:
        """Recent 5 vocabularies."""
        query = (
            select(Vocabulary)
            .where(Vocabulary.user_id == user_id)
            .order_by(Vocabulary.created_at.desc())
            .limit(limit)
        )
        result = await self.db.execute(query)
        items = list(result.scalars().all())

        return [
            DashboardStatsVocab(
                id=str(v.id), word=v.word, meaning=v.meaning,
                topic=v.topic, created_at=v.created_at,
            )
            for v in items
        ]

    async def _get_recent_quizzes(self, user_id: str, limit: int = 5) -> List[DashboardStatsQuiz]:
        """Recent 5 quizzes."""
        query = (
            select(QuizResult)
            .where(QuizResult.user_id == user_id)
            .order_by(QuizResult.completed_at.desc())
            .limit(limit)
        )
        result = await self.db.execute(query)
        items = list(result.scalars().all())

        return [
            DashboardStatsQuiz(
                id=str(q.id), quiz_type=q.quiz_type,
                total_questions=q.total_questions, correct_answers=q.correct_answers,
                score_percent=float(q.score_percent), completed_at=q.completed_at,
            )
            for q in items
        ]
