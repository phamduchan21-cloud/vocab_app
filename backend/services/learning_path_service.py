import math
import uuid
from datetime import date, datetime, timezone
from typing import Optional

from sqlalchemy import distinct, func, select, text
from sqlalchemy.ext.asyncio import AsyncSession

from models import (
    MockTest,
    QuizResult,
    User,
    UserAchievement,
    UserLearningPath,
    UserPathStep,
    UserReward,
    Vocabulary,
)
from schemas import (
    CompletePathStepResponse,
    LearningPathResponse,
    LearningPathStepResponse,
    RewardItemResponse,
    TodayLearningPlanResponse,
)


PATH_CATALOG = [
    {
        "cefr": "A1",
        "title": "Khởi hành",
        "description": "Xây nền giao tiếp và thói quen hằng ngày.",
        "lessons": [1, 2, 3, 4],
        "topics": ["greetings", "family", "numbers", "daily"],
    },
    {
        "cefr": "A2",
        "title": "Giao tiếp hằng ngày",
        "description": "Tự tin trong các tình huống quen thuộc.",
        "lessons": [5, 6, 7, 8],
        "topics": ["food", "travel", "shopping", "weather"],
    },
    {
        "cefr": "B1",
        "title": "Độc lập",
        "description": "Hiểu và diễn đạt trong học tập, công việc.",
        "lessons": [9, 10, 11, 12],
        "topics": ["health", "work", "education", "entertainment"],
    },
    {
        "cefr": "B2",
        "title": "Tự tin học thuật",
        "description": "Làm chủ ngữ cảnh phức tạp và ý tưởng trừu tượng.",
        "lessons": [13, 14, 15],
        "topics": ["technology", "emotions", "society"],
    },
]

LEGACY_TO_CEFR = {
    "beginner": "A1",
    "elementary": "A2",
    "intermediate": "B1",
    "upper_intermediate": "B2",
    "advanced": "B2",
    "proficient": "B2",
}
CEFR_TO_LEGACY = {
    "A1": "beginner",
    "A2": "elementary",
    "B1": "intermediate",
    "B2": "upper_intermediate",
}
MINI_TEST_LEVEL = {
    "A1": "beginner",
    "A2": "beginner",
    "B1": "intermediate",
    "B2": "advanced",
}


class LearningPathService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_path(self, user: User) -> LearningPathResponse:
        path, stored_steps = await self._ensure_path(user)
        response_steps = []
        for index, catalog in enumerate(PATH_CATALOG):
            stored = stored_steps[catalog["cefr"]]
            metrics = await self._step_metrics(user.id, catalog)
            if stored.status not in {"completed", "waived"}:
                stored.status = "current" if index == path.current_step else "locked"
            stored.progress_percent = metrics["progress"]
            stored.quiz_average = metrics["quiz"]
            stored.mini_test_score = metrics["mini_test"]
            response_steps.append(
                LearningPathStepResponse(
                    cefr_level=catalog["cefr"],
                    title=catalog["title"],
                    description=catalog["description"],
                    lesson_ids=catalog["lessons"],
                    topics=catalog["topics"],
                    status=stored.status,
                    progress_percent=metrics["progress"],
                    mastery_percent=metrics["mastery"],
                    quiz_average=metrics["quiz"],
                    mini_test_score=metrics["mini_test"],
                    completed_topics=metrics["completed_topics"],
                    required_topics=len(catalog["topics"]),
                    can_complete=metrics["can_complete"],
                    reason=metrics["reason"],
                )
            )
        await self.db.commit()
        overall = sum(step.progress_percent for step in response_steps) / len(
            response_steps
        )
        return LearningPathResponse(
            current_cefr=path.current_cefr,
            current_step=path.current_step,
            placement_source=path.placement_source,
            overall_progress=round(overall, 1),
            steps=response_steps,
        )

    async def get_today_plan(self, user: User) -> TodayLearningPlanResponse:
        path, _ = await self._ensure_path(user)
        due_reviews = await self.db.scalar(
            select(func.count())
            .select_from(Vocabulary)
            .where(
                Vocabulary.user_id == user.id,
                Vocabulary.next_review_date.is_not(None),
                Vocabulary.next_review_date <= date.today(),
            )
        ) or 0
        daily_goal = max(5, user.daily_word_goal or 10)
        review_target = min(due_reviews, math.ceil(daily_goal * 0.7))
        new_words = max(1, daily_goal - review_target)
        minutes = int(
            (user.learning_goals or {}).get(
                "daily_minutes",
                max(10, math.ceil(daily_goal * 1.5)),
            )
        )
        if due_reviews:
            reason = f"Bạn còn {due_reviews} từ đến hạn ôn hôm nay."
        else:
            reason = f"Chặng {path.current_cefr} đang sẵn sàng với từ mới."
        return TodayLearningPlanResponse(
            cefr_level=path.current_cefr,
            due_reviews=review_target,
            new_words=new_words,
            activity_title="Quiz củng cố theo chặng",
            activity_route="/quiz",
            estimated_minutes=minutes,
            reason=reason,
        )

    async def place_user(
        self,
        user: User,
        cefr_level: str,
        source: str,
    ) -> LearningPathResponse:
        path, steps = await self._ensure_path(user)
        target_index = self._index_for(cefr_level)
        path.current_cefr = cefr_level
        path.current_step = target_index
        path.placement_source = source
        for index, catalog in enumerate(PATH_CATALOG):
            step = steps[catalog["cefr"]]
            if index < target_index:
                step.status = "waived"
                step.completed_at = None
            elif index == target_index:
                step.status = "current"
            else:
                step.status = "locked"
        user.english_level = CEFR_TO_LEGACY[cefr_level]
        await self.db.commit()
        return await self.get_path(user)

    async def complete_step(
        self,
        user: User,
        cefr_level: str,
    ) -> CompletePathStepResponse:
        path, steps = await self._ensure_path(user)
        index = self._index_for(cefr_level)
        if index != path.current_step:
            raise ValueError("Chặng này chưa phải chặng học hiện tại.")
        catalog = PATH_CATALOG[index]
        metrics = await self._step_metrics(user.id, catalog)
        if not metrics["can_complete"]:
            raise ValueError(metrics["reason"])

        step = steps[cefr_level]
        step.status = "completed"
        step.progress_percent = 100
        step.completed_at = datetime.now(timezone.utc)
        next_level: Optional[str] = None
        if index < len(PATH_CATALOG) - 1:
            next_level = PATH_CATALOG[index + 1]["cefr"]
            path.current_step = index + 1
            path.current_cefr = next_level
            steps[next_level].status = "current"
            user.english_level = CEFR_TO_LEGACY[next_level]

        reward = await self._unlock_completion_reward(user.id, cefr_level)
        await self.db.commit()
        return CompletePathStepResponse(
            completed_level=cefr_level,
            next_level=next_level,
            reward=RewardItemResponse.model_validate(reward),
            message=f"Đã hoàn thành chặng {cefr_level}. Quà đang chờ trong Album tem.",
        )

    async def _ensure_path(
        self,
        user: User,
    ) -> tuple[UserLearningPath, dict[str, UserPathStep]]:
        path = await self.db.get(UserLearningPath, user.id)
        if path is None:
            cefr = LEGACY_TO_CEFR.get(user.english_level or "", "A1")
            current_index = self._index_for(cefr)
            await self.db.execute(
                text(
                    """
                    INSERT INTO user_learning_paths (
                        user_id, current_cefr, current_step, placement_source
                    )
                    VALUES (
                        :user_id, :current_cefr, :current_step, :placement_source
                    )
                    ON CONFLICT (user_id) DO NOTHING
                    """
                ),
                {
                    "user_id": user.id,
                    "current_cefr": cefr,
                    "current_step": current_index,
                    "placement_source": (
                        "profile" if user.english_level else "onboarding"
                    ),
                },
            )
            await self.db.flush()
            path = await self.db.get(UserLearningPath, user.id)
            if path is None:
                raise RuntimeError("Không thể khởi tạo lộ trình học.")

        for index, catalog in enumerate(PATH_CATALOG):
            cefr = catalog["cefr"]
            status = "current" if index == path.current_step else "locked"
            if index < path.current_step:
                status = "waived"
            await self.db.execute(
                text(
                    """
                    INSERT INTO user_path_steps (
                        id, user_id, cefr_level, status,
                        progress_percent, quiz_average, mini_test_score
                    )
                    VALUES (:id, :user_id, :cefr_level, :status, 0, 0, 0)
                    ON CONFLICT (user_id, cefr_level) DO NOTHING
                    """
                ),
                {
                    "id": str(uuid.uuid4()),
                    "user_id": user.id,
                    "cefr_level": cefr,
                    "status": status,
                },
            )
        await self.db.flush()
        result = await self.db.execute(
            select(UserPathStep).where(UserPathStep.user_id == user.id)
        )
        steps = {step.cefr_level: step for step in result.scalars()}
        return path, steps

    async def _step_metrics(self, user_id: str, catalog: dict) -> dict:
        lessons = catalog["lessons"]
        total = await self.db.scalar(
            select(func.count())
            .select_from(Vocabulary)
            .where(Vocabulary.user_id == user_id, Vocabulary.lesson_id.in_(lessons))
        ) or 0
        mastered = await self.db.scalar(
            select(func.count())
            .select_from(Vocabulary)
            .where(
                Vocabulary.user_id == user_id,
                Vocabulary.lesson_id.in_(lessons),
                Vocabulary.review_count >= 3,
                Vocabulary.times_correct > Vocabulary.times_wrong,
            )
        ) or 0
        completed_topics = await self.db.scalar(
            select(func.count(distinct(Vocabulary.lesson_id))).where(
                Vocabulary.user_id == user_id,
                Vocabulary.lesson_id.in_(lessons),
            )
        ) or 0
        quiz_rows = await self.db.execute(
            select(QuizResult.score_percent)
            .where(
                QuizResult.user_id == user_id,
                QuizResult.topic.in_(catalog["topics"]),
            )
            .order_by(QuizResult.completed_at.desc())
            .limit(3)
        )
        quiz_scores = [float(row[0]) for row in quiz_rows.fetchall()]
        quiz_average = (
            sum(quiz_scores) / len(quiz_scores) if quiz_scores else 0.0
        )
        mini_test_score = await self.db.scalar(
            select(func.max(MockTest.score_percent)).where(
                MockTest.user_id == user_id,
                MockTest.test_level == MINI_TEST_LEVEL[catalog["cefr"]],
            )
        ) or 0
        mastery = (mastered / total * 100) if total else 0.0
        topic_percent = completed_topics / len(catalog["topics"]) * 100
        progress = min(
            100.0,
            mastery * 0.60
            + min(quiz_average, 100) * 0.25
            + min(float(mini_test_score), 100) * 0.15,
        )
        can_complete = (
            total > 0
            and mastery >= 80
            and quiz_average >= 75
            and float(mini_test_score) >= 70
            and completed_topics >= len(catalog["topics"])
        )
        if total == 0:
            reason = "Hãy bắt đầu học các chủ đề trong chặng này."
        elif mastery < 80:
            reason = f"Cần thành thạo thêm từ để đạt 80% (hiện {mastery:.0f}%)."
        elif quiz_average < 75:
            reason = f"Cần đạt trung bình 75% Quiz (hiện {quiz_average:.0f}%)."
        elif float(mini_test_score) < 70:
            reason = "Cần hoàn thành Mini Test cuối chặng với ít nhất 70%."
        elif topic_percent < 100:
            reason = "Cần hoàn thành đủ các chủ đề bắt buộc."
        else:
            reason = "Bạn đã đủ điều kiện hoàn thành chặng."
        return {
            "progress": round(progress, 1),
            "mastery": round(mastery, 1),
            "quiz": round(quiz_average, 1),
            "mini_test": round(float(mini_test_score), 1),
            "completed_topics": completed_topics,
            "can_complete": can_complete,
            "reason": reason,
        }

    async def _unlock_completion_reward(
        self,
        user_id: str,
        cefr_level: str,
    ) -> UserReward:
        reward_key = f"cefr_{cefr_level.lower()}"
        reward = await self.db.scalar(
            select(UserReward).where(
                UserReward.user_id == user_id,
                UserReward.reward_key == reward_key,
            )
        )
        if reward is not None:
            return reward
        achievement = UserAchievement(
            id=str(uuid.uuid4()),
            user_id=user_id,
            achievement_key=reward_key,
            title=f"Tem hoàn thành {cefr_level}",
            description=f"Hoàn thành lộ trình {cefr_level}",
            icon="route",
        )
        reward = UserReward(
            id=str(uuid.uuid4()),
            user_id=user_id,
            reward_key=reward_key,
            source_type="learning_path",
            title=f"Quà hoàn thành {cefr_level}",
            description="Phần thưởng cho một chặng học bền bỉ.",
            xp_amount=250,
            gems_amount=25,
            status="pending",
        )
        self.db.add_all([achievement, reward])
        await self.db.flush()
        return reward

    @staticmethod
    def _index_for(cefr_level: str) -> int:
        for index, item in enumerate(PATH_CATALOG):
            if item["cefr"] == cefr_level:
                return index
        raise ValueError("Trình độ CEFR không hợp lệ.")
