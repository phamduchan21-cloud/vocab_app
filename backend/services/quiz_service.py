import random
import uuid
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


class QuizService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_categories(self) -> List[QuizCategory]:
        query = select(QuizCategory).order_by(QuizCategory.title)
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def generate_quiz(
        self, user_id: str, count: int = 5, skill_type: Optional[str] = None
    ) -> Tuple[List[QuizQuestion], int]:
        query = select(Vocabulary).where(Vocabulary.user_id == user_id)

        # Nếu là kỹ năng từ vựng, ưu tiên lấy từ cần ôn tập
        if skill_type == "vocabulary":
            from sqlalchemy import or_
            query = query.where(
                or_(
                    Vocabulary.next_review_date.is_(None),
                    Vocabulary.next_review_date <= func.current_date(),
                )
            )

        result = await self.db.execute(query)
        all_vocabs = list(result.scalars().all())

        if len(all_vocabs) < count:
            raise ValueError(
                f"Bạn cần ít nhất {count} từ vựng để tạo quiz. "
                f"Hiện có: {len(all_vocabs)} từ."
            )

        selected = random.sample(all_vocabs, min(count, len(all_vocabs)))
        questions: List[QuizQuestion] = []

        for vocab in selected:
            distractors = [v for v in all_vocabs if v.id != vocab.id]
            random.shuffle(distractors)
            wrong_answers = [d.meaning for d in distractors[:3]]
            options = [vocab.meaning] + wrong_answers
            random.shuffle(options)

            questions.append(QuizQuestion(
                question=f"Nghĩa của từ '{vocab.word}' là gì?",
                options=options,
                correctAnswer=vocab.meaning,
                vocabId=str(vocab.id),
            ))

        return questions, len(questions)

    async def submit_quiz(
        self,
        user_id: str,
        quiz_type: str,
        answers: List[QuizAnswer],
        skill_type: Optional[str] = None,
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
                    metadata={"skill_type": skill_type, "correct": correct, "total": total},
                ),
            )
        except Exception:
            pass  # Gamification không critical

        return QuizResultResponse(
            id=str(result.id),
            quiz_type=result.quiz_type,
            skill_type=result.skill_type,
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
