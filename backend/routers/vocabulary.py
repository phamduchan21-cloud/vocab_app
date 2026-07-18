import math
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import Response

from database import get_db
from schemas import (
    VocabularyCreate,
    VocabularyUpdate,
    VocabularyResponse,
    ReviewRequest,
    PaginatedResponse,
    SeedTopicItem,
    SeedVocabItem,
)
from services.vocabulary_service import VocabularyService
from core.security import get_current_user
from models import User

router = APIRouter(prefix="/api/vocabularies", tags=["Vocabulary"], redirect_slashes=False)


def get_vocab_service(db: AsyncSession = Depends(get_db)) -> VocabularyService:
    return VocabularyService(db)


# ─── Lesson endpoints ────────────────────────────────────────────

@router.get("/lessons", response_model=dict)
async def get_lessons(
    service: VocabularyService = Depends(get_vocab_service),
):
    """Lấy 15 bài từ vựng."""
    return {"lessons": await service.get_lessons()}


@router.get("/lessons/{lesson_id}", response_model=dict)
async def get_lesson_vocabs(
    lesson_id: int,
    service: VocabularyService = Depends(get_vocab_service),
    current_user: User = Depends(get_current_user),
):
    """Lấy từ vựng theo bài."""
    items, total = await service.get_lesson_vocabs(user_id=current_user.id, lesson_id=lesson_id)
    return {"items": [{"id": str(v.id), "word": v.word, "meaning": v.meaning, "example": v.example, "topic": v.topic} for v in items], "total": total}


@router.get("/grammar", response_model=dict)
async def get_grammar(
    service: VocabularyService = Depends(get_vocab_service),
):
    """Lấy 3 phần ngữ pháp."""
    return {"parts": await service.get_grammar_parts()}


@router.get("/advanced", response_model=dict)
async def get_advanced(
    service: VocabularyService = Depends(get_vocab_service),
):
    """Lấy 7 giáo trình nâng cao."""
    return {"textbooks": await service.get_advanced_textbooks()}


@router.get("", response_model=PaginatedResponse)
@router.get("/", response_model=PaginatedResponse)
async def list_vocabularies(
    page: int = Query(default=1, ge=1),
    limit: int = Query(default=20, ge=1, le=100),
    search: Optional[str] = Query(default=None),
    topic: Optional[str] = Query(default=None),
    sort_by: str = Query(default="created_at", pattern="^(created_at|word|review_count|next_review_date)$"),
    sort_dir: str = Query(default="desc", pattern="^(asc|desc)$"),
    service: VocabularyService = Depends(get_vocab_service),
    current_user: User = Depends(get_current_user),
):
    """Lấy danh sách từ vựng của người dùng với phân trang, tìm kiếm và sắp xếp."""
    items, total = await service.get_list(
        user_id=current_user.id,
        page=page,
        limit=limit,
        search=search,
        topic=topic,
        sort_by=sort_by,
        sort_dir=sort_dir,
    )

    pages = math.ceil(total / limit) if total > 0 else 0

    vocab_responses = [
        VocabularyResponse(
            id=str(v.id),
            user_id=str(v.user_id),
            word=v.word,
            meaning=v.meaning,
            example=v.example,
            personal_note=v.personal_note,
            topic=v.topic,
            pronunciation=v.pronunciation,
            review_count=v.review_count or 0,
            review_interval=v.review_interval or 0,
            next_review_date=v.next_review_date,
            ease_factor=v.ease_factor or 2.5,
            times_correct=v.times_correct or 0,
            times_wrong=v.times_wrong or 0,
            is_bookmarked=v.is_bookmarked or False,
            lesson_id=v.lesson_id,
            created_at=v.created_at,
            updated_at=v.updated_at,
        )
        for v in items
    ]

    return PaginatedResponse(
        items=vocab_responses,
        total=total,
        page=page,
        pages=pages,
        limit=limit,
    )


@router.post("", response_model=VocabularyResponse, status_code=status.HTTP_201_CREATED)
@router.post("/", response_model=VocabularyResponse, status_code=status.HTTP_201_CREATED)
async def create_vocabulary(
    data: VocabularyCreate,
    service: VocabularyService = Depends(get_vocab_service),
    current_user: User = Depends(get_current_user),
):
    """Thêm từ vựng mới."""
    vocab = await service.create(user_id=current_user.id, word=data.word, meaning=data.meaning, example=data.example, topic=data.topic)
    return VocabularyResponse(
        id=str(vocab.id),
        user_id=str(vocab.user_id),
        word=vocab.word,
        meaning=vocab.meaning,
        example=vocab.example,
        personal_note=vocab.personal_note,
        topic=vocab.topic,
        pronunciation=vocab.pronunciation,
        review_count=vocab.review_count or 0,
        review_interval=vocab.review_interval or 0,
        next_review_date=vocab.next_review_date,
        ease_factor=vocab.ease_factor or 2.5,
        times_correct=vocab.times_correct or 0,
        times_wrong=vocab.times_wrong or 0,
        lesson_id=vocab.lesson_id,
        created_at=vocab.created_at,
        updated_at=vocab.updated_at,
    )


# ─── Seed Data Endpoints — MUST come BEFORE /{id} catch-all ─────────

@router.get("/seed-topics", response_model=dict)
async def get_seed_topics(
    service: VocabularyService = Depends(get_vocab_service),
):
    """Lấy danh sách 15 chủ đề từ vựng có sẵn (seed data)."""
    return {"topics": await service.get_seed_topics()}


@router.get("/seed-vocab", response_model=PaginatedResponse)
async def get_seed_vocab(
    topic: Optional[str] = Query(default=None),
    lesson_id: Optional[int] = Query(default=None),
    page: int = Query(default=1, ge=1),
    limit: int = Query(default=20, ge=1, le=500),
    search: Optional[str] = Query(default=None),
    service: VocabularyService = Depends(get_vocab_service),
):
    """Lấy từ vựng mẫu (seed data) theo chủ đề / bài học."""
    items, total = await service.get_seed_vocab(
        topic=topic, lesson_id=lesson_id, page=page, limit=limit, search=search,
    )
    pages = math.ceil(total / limit) if total > 0 else 0

    return PaginatedResponse(
        items=items,
        total=total,
        page=page,
        pages=pages,
        limit=limit,
    )


@router.get("/{id}", response_model=VocabularyResponse)
async def get_vocabulary(
    id: str,
    service: VocabularyService = Depends(get_vocab_service),
    current_user: User = Depends(get_current_user),
):
    """Lấy chi tiết một từ vựng."""
    vocab = await service.get_by_id(id=id, user_id=current_user.id)
    if not vocab:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy từ vựng",
        )
    return VocabularyResponse(
        id=str(vocab.id),
        user_id=str(vocab.user_id),
        word=vocab.word,
        meaning=vocab.meaning,
        example=vocab.example,
        personal_note=vocab.personal_note,
        topic=vocab.topic,
        pronunciation=vocab.pronunciation,
        review_count=vocab.review_count or 0,
        review_interval=vocab.review_interval or 0,
        next_review_date=vocab.next_review_date,
        ease_factor=vocab.ease_factor or 2.5,
        times_correct=vocab.times_correct or 0,
        times_wrong=vocab.times_wrong or 0,
        lesson_id=vocab.lesson_id,
        created_at=vocab.created_at,
        updated_at=vocab.updated_at,
    )


@router.put("/{id}", response_model=VocabularyResponse)
async def update_vocabulary(
    id: str,
    data: VocabularyUpdate,
    service: VocabularyService = Depends(get_vocab_service),
    current_user: User = Depends(get_current_user),
):
    """Cập nhật từ vựng."""
    vocab = await service.update(
        id=id, user_id=current_user.id,
        word=data.word, meaning=data.meaning,
        example=data.example, topic=data.topic,
        personal_note=data.personal_note,
    )
    if not vocab:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy từ vựng",
        )
    return VocabularyResponse(
        id=str(vocab.id),
        user_id=str(vocab.user_id),
        word=vocab.word,
        meaning=vocab.meaning,
        example=vocab.example,
        personal_note=vocab.personal_note,
        topic=vocab.topic,
        pronunciation=vocab.pronunciation,
        review_count=vocab.review_count or 0,
        review_interval=vocab.review_interval or 0,
        next_review_date=vocab.next_review_date,
        ease_factor=vocab.ease_factor or 2.5,
        times_correct=vocab.times_correct or 0,
        times_wrong=vocab.times_wrong or 0,
        lesson_id=vocab.lesson_id,
        created_at=vocab.created_at,
        updated_at=vocab.updated_at,
    )


@router.delete("/{id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_vocabulary(
    id: str,
    service: VocabularyService = Depends(get_vocab_service),
    current_user: User = Depends(get_current_user),
):
    """Xoá từ vựng."""
    deleted = await service.delete(id=id, user_id=current_user.id)
    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy từ vựng",
        )
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.put("/{id}/review", response_model=VocabularyResponse)
async def review_vocabulary(
    id: str,
    data: ReviewRequest,
    service: VocabularyService = Depends(get_vocab_service),
    current_user: User = Depends(get_current_user),
):
    """Gửi kết quả ôn tập từ vựng (SM-2 Spaced Repetition)."""
    vocab = await service.review_word(
        id=id,
        user_id=current_user.id,
        quality=data.quality,
    )
    if not vocab:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy từ vựng",
        )
    return VocabularyResponse(
        id=str(vocab.id),
        user_id=str(vocab.user_id),
        word=vocab.word,
        meaning=vocab.meaning,
        example=vocab.example,
        personal_note=vocab.personal_note,
        topic=vocab.topic,
        pronunciation=vocab.pronunciation,
        review_count=vocab.review_count or 0,
        review_interval=vocab.review_interval or 0,
        next_review_date=vocab.next_review_date,
        ease_factor=vocab.ease_factor or 2.5,
        times_correct=vocab.times_correct or 0,
        times_wrong=vocab.times_wrong or 0,
        lesson_id=vocab.lesson_id,
        created_at=vocab.created_at,
        updated_at=vocab.updated_at,
    )


# ─── Bookmark endpoint ──────────────────────────────────────────────

@router.post("/{id}/bookmark", response_model=VocabularyResponse)
async def toggle_bookmark(
    id: str,
    service: VocabularyService = Depends(get_vocab_service),
    current_user: User = Depends(get_current_user),
):
    """Bật/tắt đánh dấu bookmark cho một từ vựng."""
    vocab = await service.toggle_bookmark(id=id, user_id=current_user.id)
    if not vocab:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy từ vựng",
        )
    return VocabularyResponse(
        id=str(vocab.id),
        user_id=str(vocab.user_id),
        word=vocab.word,
        meaning=vocab.meaning,
        example=vocab.example,
        personal_note=vocab.personal_note,
        topic=vocab.topic,
        pronunciation=vocab.pronunciation,
        review_count=vocab.review_count or 0,
        review_interval=vocab.review_interval or 0,
        next_review_date=vocab.next_review_date,
        ease_factor=vocab.ease_factor or 2.5,
        times_correct=vocab.times_correct or 0,
        times_wrong=vocab.times_wrong or 0,
        is_bookmarked=vocab.is_bookmarked or False,
        lesson_id=vocab.lesson_id,
        created_at=vocab.created_at,
        updated_at=vocab.updated_at,
    )


@router.get("/bookmarked/all", response_model=PaginatedResponse)
async def list_bookmarked(
    page: int = Query(default=1, ge=1),
    limit: int = Query(default=50, ge=1, le=200),
    service: VocabularyService = Depends(get_vocab_service),
    current_user: User = Depends(get_current_user),
):
    """Lấy danh sách từ vựng đã đánh dấu bookmark."""
    items, total = await service.get_list(
        user_id=current_user.id,
        page=page,
        limit=limit,
        bookmarked_only=True,
    )
    pages = math.ceil(total / limit) if total > 0 else 0
    vocab_responses = [
        VocabularyResponse(
            id=str(v.id),
            user_id=str(v.user_id),
            word=v.word,
            meaning=v.meaning,
            example=v.example,
            personal_note=v.personal_note,
            topic=v.topic,
            pronunciation=v.pronunciation,
            review_count=v.review_count or 0,
            review_interval=v.review_interval or 0,
            next_review_date=v.next_review_date,
            ease_factor=v.ease_factor or 2.5,
            times_correct=v.times_correct or 0,
            times_wrong=v.times_wrong or 0,
            is_bookmarked=v.is_bookmarked or False,
            lesson_id=v.lesson_id,
            created_at=v.created_at,
            updated_at=v.updated_at,
        )
        for v in items
    ]
    return PaginatedResponse(
        items=vocab_responses,
        total=total,
        page=page,
        pages=pages,
        limit=limit,
    )


# ─── Seed Data Endpoints ─────────────────────────────────────────────
# (đã định nghĩa ở trên)
