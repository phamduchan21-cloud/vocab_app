import uuid
from typing import List, Optional

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

from models import Vocabulary


# 15 bài từ vựng seed data
VOCAB_LESSONS = [
    {"id": 1, "title": "Greetings & Introductions", "icon": "👋", "count": 30, "description": "Chào hỏi và giới thiệu bản thân"},
    {"id": 2, "title": "Family & Relationships", "icon": "👨‍👩‍👧‍👦", "count": 25, "description": "Gia đình và các mối quan hệ"},
    {"id": 3, "title": "Numbers, Time & Dates", "icon": "🔢", "count": 30, "description": "Số đếm, thời gian và ngày tháng"},
    {"id": 4, "title": "Daily Routines", "icon": "🌅", "count": 30, "description": "Sinh hoạt hàng ngày"},
    {"id": 5, "title": "Food & Drinks", "icon": "🍜", "count": 35, "description": "Đồ ăn và thức uống"},
    {"id": 6, "title": "Travel & Directions", "icon": "✈️", "count": 30, "description": "Du lịch và chỉ đường"},
    {"id": 7, "title": "Shopping & Prices", "icon": "🛒", "count": 30, "description": "Mua sắm và giá cả"},
    {"id": 8, "title": "Weather & Seasons", "icon": "⛅", "count": 25, "description": "Thời tiết và các mùa"},
    {"id": 9, "title": "Health & Body", "icon": "🏥", "count": 30, "description": "Sức khỏe và cơ thể"},
    {"id": 10, "title": "Work & Business", "icon": "💼", "count": 35, "description": "Công việc và kinh doanh"},
    {"id": 11, "title": "Education & School", "icon": "🎓", "count": 30, "description": "Giáo dục và trường học"},
    {"id": 12, "title": "Entertainment & Hobbies", "icon": "🎮", "count": 25, "description": "Giải trí và sở thích"},
    {"id": 13, "title": "Technology & Internet", "icon": "💻", "count": 30, "description": "Công nghệ và Internet"},
    {"id": 14, "title": "Emotions & Feelings", "icon": "😊", "count": 25, "description": "Cảm xúc và tình cảm"},
    {"id": 15, "title": "Society & Culture", "icon": "🌍", "count": 30, "description": "Xã hội và văn hóa"},
]

# 3 phần ngữ pháp
GRAMMAR_PARTS = [
    {
        "part": 1, "title": "Ngữ pháp cơ bản", "icon": "📗",
        "lessons": ["Present Simple", "Past Simple", "Future Simple", "Articles (a/an/the)", "Plurals", "Pronouns", "Prepositions (in/on/at)", "Modal Verbs (can/must)", "Comparatives", "Questions"],
    },
    {
        "part": 2, "title": "Ngữ pháp trung cấp", "icon": "📘",
        "lessons": ["Conditionals (if)", "Passive Voice", "Relative Clauses", "Reported Speech", "Gerunds & Infinitives", "Phrasal Verbs", "Connectors", "Present Perfect", "Past Continuous", "Wish Clauses"],
    },
    {
        "part": 3, "title": "Ngữ pháp nâng cao", "icon": "📕",
        "lessons": ["Subjunctive Mood", "Inversion", "Emphasis (cleft)", "Ellipsis", "Complex Sentences", "Literary Devices", "Formal Writing", "Academic Grammar"],
    },
]

# 7 giáo trình nâng cao
ADVANCED_TEXTBOOKS = [
    {"id": "cambridge", "title": "Cambridge English", "icon": "📘", "levels": 5, "description": "KET, PET, FCE, CAE, CPE"},
    {"id": "oxford", "title": "Oxford English", "icon": "📙", "levels": 4, "description": "Oxford Word Skills, Bookworms"},
    {"id": "ielts", "title": "IELTS", "icon": "🎯", "levels": 5, "description": "Luyện thi IELTS từ 4.0 → 8.5"},
    {"id": "toeic", "title": "TOEIC", "icon": "💼", "levels": 4, "description": "Luyện thi TOEIC 300 → 900+"},
    {"id": "toefl", "title": "TOEFL", "icon": "🌎", "levels": 4, "description": "Luyện thi TOEFL iBT"},
    {"id": "business", "title": "Business English", "icon": "🏢", "levels": 3, "description": "Tiếng Anh thương mại"},
    {"id": "communication", "title": "Giao tiếp", "icon": "🗣️", "levels": 3, "description": "Giao tiếp hàng ngày"},
]


class VocabularyService:

    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_list(
        self, user_id: str, page: int = 1, limit: int = 20,
        search: Optional[str] = None, topic: Optional[str] = None,
    ) -> tuple:
        base_query = select(Vocabulary).where(Vocabulary.user_id == user_id)
        if search:
            base_query = base_query.where(Vocabulary.word.ilike(f"%{search}%"))
        if topic and topic != "all":
            base_query = base_query.where(Vocabulary.topic == topic)
        count_query = select(func.count()).select_from(base_query.subquery())
        total = await self.db.scalar(count_query) or 0
        query = base_query.order_by(Vocabulary.created_at.desc()).offset((page - 1) * limit).limit(limit)
        result = await self.db.execute(query)
        items = list(result.scalars().all())
        return items, total

    async def get_by_id(self, id: str, user_id: str) -> Optional[Vocabulary]:
        query = select(Vocabulary).where(Vocabulary.id == id, Vocabulary.user_id == user_id)
        result = await self.db.execute(query)
        return result.scalar_one_or_none()

    async def create(self, user_id: str, word: str, meaning: str, example: Optional[str] = None, topic: str = "general", lesson_id: Optional[int] = None, pronunciation: Optional[str] = None) -> Vocabulary:
        from datetime import date, timedelta
        vocab = Vocabulary(
            id=str(uuid.uuid4()), user_id=user_id, word=word, meaning=meaning,
            example=example, pronunciation=pronunciation, topic=topic, lesson_id=lesson_id,
            next_review_date=date.today() + timedelta(days=1),
            ease_factor=2.5, review_count=0, times_correct=0, times_wrong=0,
        )
        self.db.add(vocab)
        await self.db.commit()
        await self.db.refresh(vocab)
        return vocab

    async def update(self, id: str, user_id: str, word: Optional[str] = None, meaning: Optional[str] = None, example: Optional[str] = None, pronunciation: Optional[str] = None, topic: Optional[str] = None) -> Optional[Vocabulary]:
        vocab = await self.get_by_id(id, user_id)
        if not vocab:
            return None
        if word is not None:
            vocab.word = word
        if meaning is not None:
            vocab.meaning = meaning
        if example is not None:
            vocab.example = example
        if pronunciation is not None:
            vocab.pronunciation = pronunciation
        if topic is not None:
            vocab.topic = topic
        await self.db.commit()
        await self.db.refresh(vocab)
        return vocab

    async def delete(self, id: str, user_id: str) -> bool:
        vocab = await self.get_by_id(id, user_id)
        if not vocab:
            return False
        await self.db.delete(vocab)
        await self.db.commit()
        return True

    async def review_word(self, id: str, user_id: str, quality: int) -> Optional[Vocabulary]:
        from datetime import date, timedelta
        vocab = await self.get_by_id(id, user_id)
        if not vocab:
            return None
        ef = max(1.3, (vocab.ease_factor or 2.5) + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)))
        count = vocab.review_count or 0
        interval = 1
        if quality < 3:
            count = 0
        elif count == 0:
            interval, count = 1, 1
        elif count == 1:
            interval, count = 3, 2
        elif count == 2:
            interval, count = 7, 3
        elif count == 3:
            interval, count = 16, 4
        else:
            interval, count = 30, count + 1
        vocab.ease_factor = round(ef, 2)
        vocab.review_count = count
        vocab.next_review_date = date.today() + timedelta(days=interval)
        if quality >= 3:
            vocab.times_correct = (vocab.times_correct or 0) + 1
        else:
            vocab.times_wrong = (vocab.times_wrong or 0) + 1
        await self.db.commit()
        await self.db.refresh(vocab)
        return vocab

    # ─── Lesson methods ──────────────────────────────────────

    async def get_lessons(self) -> list:
        return VOCAB_LESSONS

    async def get_lesson_vocabs(self, user_id: str, lesson_id: int) -> tuple:
        query = select(Vocabulary).where(
            Vocabulary.user_id == user_id,
            Vocabulary.lesson_id == lesson_id,
        )
        result = await self.db.execute(query)
        items = list(result.scalars().all())
        total = len(items)
        return items, total

    async def get_grammar_parts(self) -> list:
        return GRAMMAR_PARTS

    async def get_advanced_textbooks(self) -> list:
        return ADVANCED_TEXTBOOKS

    # ─── Seed data methods ────────────────────────────────────

    async def get_seed_topics(self) -> list:
        """Trả về danh sách chủ đề từ seed data."""
        from schemas import SeedTopicItem
        return [
            SeedTopicItem(
                lesson_id=lesson["id"],
                title=lesson["title"],
                icon=lesson["icon"],
                description=lesson.get("description", ""),
                count=lesson["count"],
            )
            for lesson in VOCAB_LESSONS
        ]

    async def get_seed_vocab(
        self,
        topic: Optional[str] = None,
        lesson_id: Optional[int] = None,
        page: int = 1,
        limit: int = 20,
        search: Optional[str] = None,
    ) -> tuple:
        """Lấy từ vựng mẫu (seed data) với phân trang và lọc."""
        from seed_data import SEED_VOCABULARIES
        from schemas import SeedVocabItem

        filtered = SEED_VOCABULARIES
        if topic:
            filtered = [v for v in filtered if v.get("topic") == topic]
        if lesson_id is not None:
            filtered = [v for v in filtered if v.get("lesson_id") == lesson_id]
        if search:
            q = search.lower()
            filtered = [
                v for v in filtered
                if q in v["word"].lower() or q in v["meaning"].lower()
            ]

        total = len(filtered)
        start = (page - 1) * limit
        end = start + limit
        page_items = filtered[start:end]

        items = [
            SeedVocabItem(
                word=v["word"],
                meaning=v["meaning"],
                example=v.get("example"),
                pronunciation=v.get("pronunciation"),
                topic=v.get("topic", "general"),
                lesson_id=v.get("lesson_id"),
            )
            for v in page_items
        ]

        return items, total
