from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel

from database import get_db
from core.security import get_current_user
from models import User
from seed_data import SEED_VOCABULARIES
from services.ai_service import AIService

router = APIRouter(prefix="/api/ai", tags=["AI"], redirect_slashes=False)


# ─── Schemas ─────────────────────────────────────────────────────────


class GenerateQuizRequest(BaseModel):
    count: int = 10
    topic: Optional[str] = "general"
    level: str = "intermediate"


class ChatRequest(BaseModel):
    message: str
    context: Optional[dict] = None


class ExplainWordRequest(BaseModel):
    word: str
    meaning: Optional[str] = ""
    context: Optional[str] = ""


class AIQuestion(BaseModel):
    question: str
    options: list[str]
    correctAnswer: str


class GenerateQuizResponse(BaseModel):
    questions: list[AIQuestion]
    total: int


class ChatResponse(BaseModel):
    reply: str
    suggestions: list[str] = []


class ExplainWordResponse(BaseModel):
    explanation: str
    examples: list[str] = []
    synonyms: list[str] = []
    tips: str = ""


# ─── Topic mapping ────────────────────────────────────────────────────
# Seed topic keys (internal)
SEED_TOPIC_KEYS = {s["topic"] for s in SEED_VOCABULARIES}

# Display title → seed key mapping (VD: "Travel & Directions" → "travel")
from services.vocabulary_service import VOCAB_LESSONS

DISPLAY_TO_SEED_KEY = {}
for lesson in VOCAB_LESSONS:
    title_lower = lesson["title"].lower()
    for sv in SEED_VOCABULARIES:
        if sv.get("lesson_id") == lesson["id"]:
            DISPLAY_TO_SEED_KEY[title_lower] = sv["topic"]
            break


def _resolve_topic(topic: Optional[str]) -> Optional[str]:
    """Chuyển đổi topic về internal key. Trả về None nếu là 'all'."""
    if not topic or topic == "all":
        return None
    # Nếu đã là internal key
    if topic in SEED_TOPIC_KEYS:
        return topic
    # Thử display title
    tl = topic.lower().strip()
    if tl in DISPLAY_TO_SEED_KEY:
        return DISPLAY_TO_SEED_KEY[tl]
    # Thử làm sạch
    cleaned = tl.replace(" & ", "_").replace(" ", "_")
    for st in SEED_TOPIC_KEYS:
        if st.lower() == cleaned:
            return st
    return None  # fallback: lấy tất cả


# ─── Endpoints ─────────────────────────────────────────────────────────


@router.post("/generate-quiz", response_model=GenerateQuizResponse)
async def ai_generate_quiz(
    data: GenerateQuizRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Sinh câu hỏi quiz bằng AI dựa trên từ vựng của user + seed data."""
    from sqlalchemy import select
    from models import Vocabulary

    topic_key = _resolve_topic(data.topic)

    # Lấy user vocabulary (có filter topic nếu có)
    query = select(Vocabulary).where(Vocabulary.user_id == current_user.id)
    if topic_key:
        query = query.where(Vocabulary.topic == topic_key)
    result = await db.execute(query)
    user_vocabs = list(result.scalars().all())

    # Luôn gộp seed data + user vocabs
    seen_words = set()
    combined = []

    # User vocabs trước
    for v in user_vocabs:
        combined.append({"word": v.word, "meaning": v.meaning})
        seen_words.add(v.word.lower())

    # Seed data (lọc theo topic nếu có)
    for seed in SEED_VOCABULARIES:
        word = seed.get("word", "")
        if word.lower() not in seen_words:
            if not topic_key or seed.get("topic") == topic_key:
                combined.append({"word": word, "meaning": seed.get("meaning", "")})
                seen_words.add(word.lower())

    # Fallback: nếu topic filter ra rỗng, lấy TẤT CẢ seed
    if not combined:
        for seed in SEED_VOCABULARIES:
            combined.append({"word": seed.get("word", ""), "meaning": seed.get("meaning", "")})

    # Luôn có từ vựng vì seed data đã có sẵn
    ai = AIService()
    try:
        questions = await ai.generate_quiz(
            vocabs=combined,
            count=data.count,
            topic=topic_key or "general",
            level=data.level,
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"AI hiện không khả dụng: {str(e)}. Vui lòng thử lại sau.",
        )

    return GenerateQuizResponse(
        questions=[AIQuestion(**q) for q in questions],
        total=len(questions),
    )


@router.post("/chat", response_model=ChatResponse)
async def ai_chat(
    data: ChatRequest,
    current_user: User = Depends(get_current_user),
):
    """Chat với AI Tutor Meu về từ vựng / ngữ pháp."""
    ai = AIService()
    try:
        result = await ai.chat(
            message=data.message,
            context=data.context or {},
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"AI hiện không khả dụng: {str(e)}. Vui lòng thử lại sau.",
        )

    return ChatResponse(
        reply=result.get("reply", "Xin lỗi, tôi chưa có câu trả lời ngay."),
        suggestions=result.get("suggestions", [
            "Giải thích từ 'resilient'",
            "Ví dụ với từ 'genuine'",
            "Phân biệt 'affect' và 'effect'",
        ]),
    )


@router.post("/explain-word", response_model=ExplainWordResponse)
async def ai_explain_word(
    data: ExplainWordRequest,
    current_user: User = Depends(get_current_user),
):
    """Giải thích chi tiết một từ vựng bằng AI."""
    ai = AIService()
    try:
        result = await ai.explain_word(
            word=data.word,
            meaning=data.meaning or "",
            context=data.context or "",
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"AI hiện không khả dụng: {str(e)}. Vui lòng thử lại sau.",
        )

    return ExplainWordResponse(
        explanation=result.get("explanation", ""),
        examples=result.get("examples", []),
        synonyms=result.get("synonyms", []),
        tips=result.get("tips", ""),
    )
