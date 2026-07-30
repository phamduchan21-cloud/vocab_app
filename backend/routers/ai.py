from typing import Optional
import time
import logging

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from database import get_db
from core.security import get_current_user
from models import User, Vocabulary
from seed_data import SEED_VOCABULARIES
from services.ai_service import AIService, AIUnavailableError, get_ai_service
from services.vocabulary_service import VOCAB_LESSONS

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/ai", tags=["AI"], redirect_slashes=False)


# ─── In-memory rate limiter ─────────────────────────────────────────

class _RateLimiter:
    """ponytail: simple dict, upgrade to Redis if multi-instance."""
    def __init__(self):
        self._buckets: dict[str, list[float]] = {}

    def check(self, key: str, max_reqs: int, window_secs: int) -> bool:
        now = time.time()
        timestamps = self._buckets.get(key, [])
        timestamps = [t for t in timestamps if now - t < window_secs]
        if len(timestamps) >= max_reqs:
            self._buckets[key] = timestamps
            return False
        timestamps.append(now)
        self._buckets[key] = timestamps
        return True


_limiter = _RateLimiter()


# ─── Schemas ────────────────────────────────────────────────────────

class GenerateQuizRequest(BaseModel):
    count: int = Field(default=10, ge=1, le=30)
    topic: Optional[str] = Field(default="general", max_length=50)
    level: str = Field(default="intermediate", max_length=20)


class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=2000)
    context: Optional[dict] = None


class ExplainWordRequest(BaseModel):
    word: str = Field(..., min_length=1, max_length=100)
    meaning: Optional[str] = Field(default="", max_length=500)
    context: Optional[str] = Field(default="", max_length=1000)


class AIQuestion(BaseModel):
    question: str
    options: list[str]
    correctAnswer: str


class GenerateQuizResponse(BaseModel):
    questions: list[AIQuestion]
    total: int


class ChatResponse(BaseModel):
    reply: str
    suggestions: list[str] = Field(default_factory=list)


class ExplainWordResponse(BaseModel):
    explanation: str
    examples: list[str] = Field(default_factory=list)
    synonyms: list[str] = Field(default_factory=list)
    tips: str = ""


class AIProviderStatus(BaseModel):
    name: str
    state: str
    calls: int
    successes: int
    failures: int
    average_latency_ms: float
    last_error_code: Optional[str] = None


class AIStatusResponse(BaseModel):
    status: str
    provider_count: int
    providers: list[AIProviderStatus]


# ─── Helpers ────────────────────────────────────────────────────────

def _check_ratelimit(user_id: str, endpoint: str, max_reqs: int, window_secs: int):
    key = f"{user_id}:{endpoint}"
    if not _limiter.check(key, max_reqs, window_secs):
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Bạn đã gửi quá nhiều yêu cầu. Vui lòng đợi một lát rồi thử lại.",
        )


def _raise_ai_unavailable(operation: str, error: AIUnavailableError) -> None:
    logger.error(
        "ai_request_unavailable",
        extra={
            "event": "ai_request",
            "operation": operation,
            "outcome": "failure",
            "error_code": error.code,
        },
    )
    raise HTTPException(
        status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        detail={
            "code": error.code,
            "message": "Sol đang tạm gián đoạn kết nối AI. Vui lòng thử lại sau ít phút.",
            "retryable": error.retryable,
        },
        headers={"Retry-After": "30", "X-AI-Error-Code": error.code},
    )


def _resolve_topic(topic: Optional[str]) -> Optional[str]:
    """Chuyển đổi topic về internal key. Trả về None nếu là 'all'."""
    if not topic or topic == "all":
        return None
    seed_topic_keys = {s["topic"] for s in SEED_VOCABULARIES}
    if topic in seed_topic_keys:
        return topic
    display_to_seed = {}
    for lesson in VOCAB_LESSONS:
        title_lower = lesson["title"].lower()
        for sv in SEED_VOCABULARIES:
            if sv.get("lesson_id") == lesson["id"]:
                display_to_seed[title_lower] = sv["topic"]
                break
    tl = topic.lower().strip()
    if tl in display_to_seed:
        return display_to_seed[tl]
    cleaned = tl.replace(" & ", "_").replace(" ", "_")
    for st in seed_topic_keys:
        if st.lower() == cleaned:
            return st
    return None


def _build_vocab_list(current_user_id: str, db: AsyncSession, topic_key: Optional[str]) -> list[dict]:
    """Gộp user vocabulary + seed data."""
    import asyncio
    query = select(Vocabulary).where(Vocabulary.user_id == current_user_id)
    if topic_key:
        query = query.where(Vocabulary.topic == topic_key)
    result = asyncio.run_coroutine_threadsafe(
        db.execute(query), asyncio.get_event_loop()
    )
    user_vocabs = list(result.scalars().all())
    seen_words = set()
    combined = []
    for v in user_vocabs:
        combined.append({"word": v.word, "meaning": v.meaning})
        seen_words.add(v.word.lower())
    for seed in SEED_VOCABULARIES:
        word = seed.get("word", "")
        if word.lower() not in seen_words:
            if not topic_key or seed.get("topic") == topic_key:
                combined.append({"word": word, "meaning": seed.get("meaning", "")})
                seen_words.add(word.lower())
    if not combined:
        for seed in SEED_VOCABULARIES:
            combined.append({"word": seed.get("word", ""), "meaning": seed.get("meaning", "")})
    return combined


async def _collect_vocabs(
    user_id: str, db: AsyncSession, topic_key: Optional[str]
) -> list[dict]:
    """Gộp user vocabulary + seed data."""
    query = select(Vocabulary).where(Vocabulary.user_id == user_id)
    if topic_key:
        query = query.where(Vocabulary.topic == topic_key)
    result = await db.execute(query)
    user_vocabs = list(result.scalars().all())

    seen_words = set()
    combined = []
    for v in user_vocabs:
        combined.append({"word": v.word, "meaning": v.meaning})
        seen_words.add(v.word.lower())
    for seed in SEED_VOCABULARIES:
        word = seed.get("word", "")
        if word.lower() not in seen_words:
            if not topic_key or seed.get("topic") == topic_key:
                combined.append({"word": word, "meaning": seed.get("meaning", "")})
                seen_words.add(word.lower())
    if not combined:
        for seed in SEED_VOCABULARIES:
            combined.append({"word": seed.get("word", ""), "meaning": seed.get("meaning", "")})
    return combined


# ─── Endpoints ──────────────────────────────────────────────────────

@router.post("/generate-quiz", response_model=GenerateQuizResponse)
async def ai_generate_quiz(
    data: GenerateQuizRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    ai: AIService = Depends(get_ai_service),
):
    """Sinh câu hỏi quiz bằng AI dựa trên từ vựng của user + seed data."""
    _check_ratelimit(current_user.id, "generate-quiz", max_reqs=10, window_secs=3600)

    topic_key = _resolve_topic(data.topic)
    combined = await _collect_vocabs(current_user.id, db, topic_key)

    try:
        questions = await ai.generate_quiz(
            vocabs=combined,
            count=data.count,
            topic=topic_key or "general",
            level=data.level,
        )
    except AIUnavailableError as error:
        _raise_ai_unavailable("generate_quiz", error)

    return GenerateQuizResponse(
        questions=[AIQuestion(**q) for q in questions],
        total=len(questions),
    )


@router.post("/chat", response_model=ChatResponse)
async def ai_chat(
    data: ChatRequest,
    current_user: User = Depends(get_current_user),
    ai: AIService = Depends(get_ai_service),
):
    """Chat với AI Tutor Meu về từ vựng / ngữ pháp."""
    _check_ratelimit(current_user.id, "chat", max_reqs=30, window_secs=3600)

    try:
        result = await ai.chat(
            message=data.message,
            context=data.context or {},
        )
    except AIUnavailableError as error:
        _raise_ai_unavailable("chat", error)

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
    ai: AIService = Depends(get_ai_service),
):
    """Giải thích chi tiết một từ vựng bằng AI."""
    _check_ratelimit(current_user.id, "explain-word", max_reqs=30, window_secs=3600)

    try:
        result = await ai.explain_word(
            word=data.word,
            meaning=data.meaning or "",
            context=data.context or "",
        )
    except AIUnavailableError as error:
        _raise_ai_unavailable("explain_word", error)

    return ExplainWordResponse(
        explanation=result.get("explanation", ""),
        examples=result.get("examples", []),
        synonyms=result.get("synonyms", []),
        tips=result.get("tips", ""),
    )


@router.get("/status", response_model=AIStatusResponse)
async def ai_status(
    _: User = Depends(get_current_user),
    ai: AIService = Depends(get_ai_service),
):
    """Return provider health without exposing credentials or prompts."""
    return AIStatusResponse(**ai.health_snapshot())
