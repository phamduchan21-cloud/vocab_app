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
from seed_data import SEED_VOCABULARIES

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

    async def _build_questions(
        self, vocabs: list, count: int, level: str
    ) -> List[MockTestQuestion]:
        """Xây dựng câu hỏi phù hợp với cấp độ."""
        selected = random.sample(vocabs, min(count, len(vocabs)))
        questions: List[MockTestQuestion] = []

        for i, vocab in enumerate(selected):
            if isinstance(vocab, dict):
                word = vocab["word"]
                meaning = vocab["meaning"]
                example = vocab.get("example", "")
                all_meanings = [v["meaning"] for v in vocabs if v["word"] != word]
                all_words = [v["word"] for v in vocabs if v["word"] != word]
            else:
                word = vocab.word
                meaning = vocab.meaning
                example = vocab.example or ""
                all_meanings = [v.meaning for v in vocabs if v.id != vocab.id]
                all_words = [v.word for v in vocabs if v.id != vocab.id]

            random.shuffle(all_meanings)
            random.shuffle(all_words)

            # Level-based question types
            if level == "beginner":
                questions.append(MockTestQuestion(
                    question=f"Nghĩa của từ '{word}' là gì?",
                    options=[meaning] + all_meanings[:3],
                    correctAnswer=meaning,
                    difficulty="easy",
                    question_type="meaning_match",
                ))
            elif level == "intermediate" and example and len(example) > 5:
                # Fill-in-blank: thay word bằng ____
                blank_q = example.replace(word, "______", 1).replace(word.capitalize(), "______", 1)
                questions.append(MockTestQuestion(
                    question=f"Điền từ thích hợp: '{blank_q}'",
                    options=[word] + all_words[:3],
                    correctAnswer=word,
                    difficulty="medium",
                    question_type="fill_blank",
                ))
            else:
                # Fallback: definition-to-word
                questions.append(MockTestQuestion(
                    question=f"Từ nào có nghĩa là '{meaning}'?",
                    options=[word] + all_words[:3],
                    correctAnswer=word,
                    difficulty="medium",
                    question_type="definition_match",
                ))

            # Shuffle options for last question
            if level == "beginner":
                opts = questions[-1].options[:]
                random.shuffle(opts)
                questions[-1].options = opts
            else:
                opts = questions[-1].options[:]
                random.shuffle(opts)
                questions[-1].options = opts

        return questions

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

        # Fallback to seed data if not enough vocab
        if len(all_vocabs) < count:
            seed_vocabs = SEED_VOCABULARIES
            if topic:
                seed_vocabs = [v for v in seed_vocabs if v.get("topic") == topic]
            combined = list(all_vocabs) + seed_vocabs
            if len(combined) < count:
                raise ValueError(
                    f"Bạn cần ít nhất {count} từ vựng để tạo đề thi. "
                    f"Hiện có: {len(combined)} từ."
                )
            questions = await self._build_questions(combined, count, level)
            test_id = str(uuid.uuid4())
            return test_id, questions, count, duration

        questions = await self._build_questions(all_vocabs, count, level)
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

    async def get_available_topics(self, user_id: str) -> list:
        """Lấy danh sách chủ đề có thể kiểm tra."""
        # Topics from user's vocabulary
        query = select(Vocabulary.topic).where(
            Vocabulary.user_id == user_id,
            Vocabulary.topic.isnot(None),
            Vocabulary.topic != "",
        ).distinct()
        result = await self.db.execute(query)
        user_topics = [row[0] for row in result.fetchall()]

        # Topics from seed data
        seed_topics = list(set(
            v.get("topic", "general") for v in SEED_VOCABULARIES
            if v.get("topic")
        ))

        union = list(set(user_topics + seed_topics))
        union.sort()
        return union
