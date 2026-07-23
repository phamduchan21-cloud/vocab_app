import uuid
from datetime import date, timedelta

import pytest

from database import async_session_factory, init_db
from models import User
from services.vocabulary_service import VocabularyService


@pytest.mark.asyncio
async def test_sm2_advances_then_resets_a_review_schedule():
    await init_db()
    user_id = str(uuid.uuid4())

    async with async_session_factory() as session:
        session.add(
            User(
                id=user_id,
                email=f"{user_id}@example.com",
                username="SM2 Tester",
            )
        )
        await session.commit()
        service = VocabularyService(session)
        vocabulary = await service.create(
            user_id=user_id,
            word="resilient",
            meaning="kiên cường",
        )

        first_review = await service.review_word(
            vocabulary.id,
            user_id,
            quality=5,
        )
        assert first_review is not None
        assert first_review.review_count == 1
        assert first_review.review_interval == 1
        assert first_review.next_review_date == date.today() + timedelta(days=1)
        assert first_review.times_correct == 1

        second_review = await service.review_word(
            vocabulary.id,
            user_id,
            quality=4,
        )
        assert second_review is not None
        assert second_review.review_count == 2
        assert second_review.review_interval == 6
        assert second_review.next_review_date == date.today() + timedelta(days=6)
        assert second_review.times_correct == 2

        failed_review = await service.review_word(
            vocabulary.id,
            user_id,
            quality=2,
        )
        assert failed_review is not None
        assert failed_review.review_count == 0
        assert failed_review.review_interval == 1
        assert failed_review.next_review_date == date.today() + timedelta(days=1)
        assert failed_review.times_wrong == 1
