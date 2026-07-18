import random
import uuid
import logging
from typing import List, Optional, Tuple

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

from models import Vocabulary, QuizResult, QuizCategory
from schemas import (
    QuizSubmit,
    QuizAnswer,
    QuizResultResponse,
    QuizQuestion,
)
from seed_data import SEED_VOCABULARIES
from question_bank import QUESTION_BANK, get_questions

logger = logging.getLogger(__name__)


def _bank_question_to_quiz(bq: dict) -> QuizQuestion:
    """Convert question bank dict to QuizQuestion schema."""
    return QuizQuestion(
        question=bq["question"],
        options=bq["options"],
        correctAnswer=bq["correctAnswer"],
        vocabId=bq.get("id", ""),
        explanation=bq.get("explanation", ""),
        transcript=bq.get("transcript"),
        level=bq.get("level", "A2"),
    )


class QuizService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_categories(self) -> List[QuizCategory]:
        query = select(QuizCategory).order_by(QuizCategory.title)
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def _build_questions_from_vocab_list(
        self, vocabs: list, count: int
    ) -> Tuple[List[QuizQuestion], List]:
        """Xây dựng câu hỏi quiz từ danh sách từ vựng (model objects hoặc dicts)."""
        selected = random.sample(vocabs, min(count, len(vocabs)))
        questions: List[QuizQuestion] = []

        for i, vocab in enumerate(selected):
            # Hỗ trợ cả model object và dict (seed data)
            if isinstance(vocab, dict):
                word = vocab["word"]
                meaning = vocab["meaning"]
                vid = f"seed_{i}"
                all_meanings = [v["meaning"] for v in vocabs if v["word"] != word]
            else:
                word = vocab.word
                meaning = vocab.meaning
                vid = str(vocab.id)
                all_meanings = [v.meaning for v in vocabs if v.id != vocab.id]

            random.shuffle(all_meanings)
            wrong_answers = all_meanings[:3]
            options = [meaning] + wrong_answers
            random.shuffle(options)

            questions.append(QuizQuestion(
                question=f"Nghĩa của từ '{word}' là gì?",
                options=options,
                correctAnswer=meaning,
                vocabId=vid,
            ))

        return questions, len(questions)

    async def generate_quiz(
        self,
        user_id: str,
        count: int = 5,
        skill_type: Optional[str] = None,
        topic: Optional[str] = None,
    ) -> Tuple[List[QuizQuestion], int]:
        # Uu tien question bank khi co chu de cu the.
        if topic and topic != "all":
            if skill_type:
                bank_qs = get_questions(topic, skill_type, count)
            else:
                bank_qs = []
                for skill_key in ("vocabulary", "grammar", "reading", "listening"):
                    bank_qs.extend(get_questions(topic, skill_key, count))
                random.shuffle(bank_qs)
                bank_qs = bank_qs[:count]
            if bank_qs:
                return [_bank_question_to_quiz(q) for q in bank_qs], len(bank_qs)

        # Nếu topic = "all" + skill_type cụ thể, gộp từ tất cả topics trong bank
        if (not topic or topic == "all") and skill_type:
            all_bank_qs = []
            for t_key in QUESTION_BANK:
                bank_qs = get_questions(t_key, skill_type, count)
                all_bank_qs.extend(bank_qs)
            random.shuffle(all_bank_qs)
            if all_bank_qs:
                return [_bank_question_to_quiz(q) for q in all_bank_qs[:count]], min(count, len(all_bank_qs))

        # Nếu topic = "all" + skill_type = "all", mix từ bank
        if (not topic or topic == "all") and (not skill_type or skill_type == "all"):
            all_bank_qs = []
            for t_key in QUESTION_BANK:
                for s_key in ("vocabulary", "grammar", "reading", "listening"):
                    bank_qs = get_questions(t_key, s_key, count)
                    all_bank_qs.extend(bank_qs)
            random.shuffle(all_bank_qs)
            if all_bank_qs:
                return [_bank_question_to_quiz(q) for q in all_bank_qs[:count]], min(count, len(all_bank_qs))

        # Fallback: lấy từ từ vựng người dùng
        query = select(Vocabulary).where(Vocabulary.user_id == user_id)

        if topic and topic != "all":
            query = query.where(Vocabulary.topic == topic)

        result = await self.db.execute(query)
        all_vocabs = list(result.scalars().all())

        # Nếu không đủ từ → bổ sung từ seed data
        if len(all_vocabs) < count:
            seed_vocabs = SEED_VOCABULARIES
            if topic and topic != "all":
                seed_vocabs = [v for v in seed_vocabs if v.get("topic") == topic]

            if seed_vocabs:
                combined = list(all_vocabs) + seed_vocabs
                return await self._build_questions_from_vocab_list(combined, count)

            raise ValueError(
                f"Bạn cần ít nhất {count} từ vựng để tạo quiz. "
                f"Hiện có: {len(all_vocabs)} từ."
            )

        return await self._build_questions_from_vocab_list(all_vocabs, count)

    async def submit_quiz(
        self,
        user_id: str,
        quiz_type: str,
        answers: List[QuizAnswer],
        skill_type: Optional[str] = None,
        topic: Optional[str] = None,
    ) -> QuizResultResponse:
        correct = 0
        total = len(answers)
        graded_answers = []

        for answer in answers:
            is_correct = answer.selected == answer.correct_answer
            if is_correct:
                correct += 1
            graded_answers.append(QuizAnswer(
                question=answer.question,
                options=answer.options,
                selected=answer.selected,
                correct_answer=answer.correct_answer,
                vocab_id=answer.vocab_id,
                is_correct=is_correct,
            ))

        score_percent = round((correct / total) * 100, 2) if total > 0 else 0

        result = QuizResult(
            id=str(uuid.uuid4()),
            user_id=user_id,
            quiz_type=quiz_type,
            skill_type=skill_type,
            topic=topic,
            total_questions=total,
            correct_answers=correct,
            score_percent=score_percent,
            answers=[a.model_dump() for a in graded_answers],
        )
        self.db.add(result)
        await self.db.commit()
        await self.db.refresh(result)

        # Ghi nhận activity cho gamification
        try:
            from services.gamification_service import GamificationService
            gs = GamificationService(self.db)
            from schemas import RecordActivityRequest
            await gs.record_activity(
                user_id=user_id,
                request=RecordActivityRequest(
                    activity_type="quiz",
                    xp_earned=correct * 10,
                    metadata={
                        "skill_type": skill_type,
                        "topic": topic,
                        "correct": correct,
                        "total": total,
                    },
                ),
            )
        except Exception as e:
            logger.error(f"Gamification recording failed: {e}")

        return QuizResultResponse(
            id=str(result.id),
            quiz_type=result.quiz_type,
            skill_type=result.skill_type,
            topic=result.topic,
            total_questions=result.total_questions,
            correct_answers=result.correct_answers,
            score_percent=float(result.score_percent),
            completed_at=result.completed_at,
            details=result.answers,
        )

    async def get_history(
        self,
        user_id: str,
        page: int = 1,
        limit: int = 20,
        skill_type: Optional[str] = None,
    ) -> Tuple[List[QuizResult], int]:
        base_query = select(QuizResult).where(QuizResult.user_id == user_id)
        if skill_type:
            base_query = base_query.where(QuizResult.skill_type == skill_type)

        count_query = select(func.count()).select_from(base_query.subquery())
        total = await self.db.scalar(count_query) or 0

        query = (
            base_query
            .order_by(QuizResult.completed_at.desc())
            .offset((page - 1) * limit)
            .limit(limit)
        )
        result = await self.db.execute(query)
        items = list(result.scalars().all())

        return items, total
