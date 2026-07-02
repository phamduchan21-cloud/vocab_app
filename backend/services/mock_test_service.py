import random
import uuid
from typing import List, Tuple, Optional

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

from models import Vocabulary, MockTest
from schemas import (
    MockTestQuestion,
    MockTestAnswer,
    MockTestResultResponse,
    MockTestHistoryItem,
)

# Cấu hình theo level
LEVEL_CONFIG = {
    "beginner": {"total": 10, "duration": 15},
    "intermediate": {"total": 20, "duration": 30},
    "advanced": {"total": 30, "duration": 45},
}


def get_grade(score_percent: float) -> str:
    """Xếp loại dựa trên % điểm."""
    if score_percent >= 90: return "A"
    if score_percent >= 75: return "B"
    if score_percent >= 50: return "C"
    return "D"


class MockTestService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def generate(
        self, user_id: str, level: str, topic: Optional[str] = None
    ) -> Tuple[str, List[MockTestQuestion], int, int]:
        """Tạo đề kiểm tra từ vựng tiếng Anh."""
        config = LEVEL_CONFIG.get(level)
        if not config:
            raise ValueError(f"Cấp độ không hợp lệ: {level}. Hỗ trợ: beginner, intermediate, advanced")

        count = config["total"]
        duration = config["duration"]

        # Lấy từ vựng của user
        query = select(Vocabulary).where(Vocabulary.user_id == user_id)
        if topic:
            query = query.where(Vocabulary.topic == topic)

        result = await self.db.execute(query)
        all_vocabs = list(result.scalars().all())

        if len(all_vocabs) < count:
            raise ValueError(
                f"Bạn cần ít nhất {count} từ vựng để tạo đề thi. "
                f"Hiện có: {len(all_vocabs)} từ."
            )

        selected = random.sample(all_vocabs, count)
        questions: List[MockTestQuestion] = []

        for vocab in selected:
            distractors = [v for v in all_vocabs if v.id != vocab.id]
            random.shuffle(distractors)
            wrong_answers = [d.meaning for d in distractors[:3]]
            options = [vocab.meaning] + wrong_answers
            random.shuffle(options)

            questions.append(MockTestQuestion(
                question=f"Nghĩa của từ '{vocab.word}' là gì?",
                options=options,
                correctAnswer=vocab.meaning,
            ))

        test_id = str(uuid.uuid4())
        return test_id, questions, count, duration

    async def submit(
        self, user_id: str, test_id: str, answers: List[MockTestAnswer], topic: Optional[str] = None
    ) -> MockTestResultResponse:
        """Chấm điểm bài kiểm tra."""
        correct = 0
        total = len(answers)
        graded_answers = []

        for answer in answers:
            is_correct = answer.selected == answer.correct_answer
            if is_correct:
                correct += 1
            graded_answers.append(MockTestAnswer(
                question=answer.question,
                options=answer.options,
                selected=answer.selected,
                correct_answer=answer.correct_answer,
                is_correct=is_correct,
            ))

        score_percent = round((correct / total) * 100, 2) if total > 0 else 0
        grade = get_grade(score_percent)

        # Xác định level dựa trên số lượng câu
        if total <= 10:
            test_level = "beginner"
        elif total <= 20:
            test_level = "intermediate"
        else:
            test_level = "advanced"

        result = MockTest(
            id=test_id,
            user_id=user_id,
            test_level=test_level,
            total_questions=total,
            correct_answers=correct,
            score_percent=score_percent,
            grade=grade,
            topic=topic,
            answers=[a.model_dump() for a in graded_answers],
        )
        self.db.add(result)
        await self.db.commit()
        await self.db.refresh(result)

        return MockTestResultResponse(
            id=str(result.id),
            test_level=result.test_level,
            total_questions=result.total_questions,
            correct_answers=result.correct_answers,
            score_percent=float(result.score_percent),
            grade=result.grade or "C",
            topic=result.topic,
            details=result.answers,
            completed_at=result.completed_at,
        )

    async def get_history(
        self, user_id: str, page: int = 1, limit: int = 20
    ) -> Tuple[List[MockTestHistoryItem], int]:
        """Lấy lịch sử kiểm tra."""
        base_query = select(MockTest).where(MockTest.user_id == user_id)
        count_query = select(func.count()).select_from(base_query.subquery())
        total = await self.db.scalar(count_query) or 0

        query = (
            base_query
            .order_by(MockTest.completed_at.desc())
            .offset((page - 1) * limit)
            .limit(limit)
        )
        result = await self.db.execute(query)
        items = list(result.scalars().all())

        history = [
            MockTestHistoryItem(
                id=str(m.id),
                test_level=m.test_level,
                total_questions=m.total_questions,
                correct_answers=m.correct_answers,
                score_percent=float(m.score_percent),
                grade=m.grade or "C",
                completed_at=m.completed_at,
            )
            for m in items
        ]

        return history, total
