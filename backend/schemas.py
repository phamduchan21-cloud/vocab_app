from enum import Enum
from pydantic import BaseModel, Field
from typing import Optional, List, Any
from datetime import datetime, date
from decimal import Decimal


# ─── English Level ───────────────────────────────────────────────────

class EnglishLevel(str, Enum):
    beginner = "beginner"
    elementary = "elementary"
    intermediate = "intermediate"
    upper_intermediate = "upper_intermediate"
    advanced = "advanced"
    proficient = "proficient"


ENGLISH_LEVEL_LABELS = {
    "beginner": "Sơ cấp",
    "elementary": "Tiểu học",
    "intermediate": "Trung cấp",
    "upper_intermediate": "Trung cao cấp",
    "advanced": "Cao cấp",
    "proficient": "Thành thạo",
}


# ─── Auth Schemas ────────────────────────────────────────────────────

class UserCreate(BaseModel):
    email: str = Field(..., max_length=100)
    password: str = Field(..., min_length=6, max_length=128)
    username: Optional[str] = Field(None, max_length=50)


class UserLogin(BaseModel):
    email: str
    password: str


class UserResponse(BaseModel):
    id: str
    email: str
    username: Optional[str] = None
    is_premium: bool = False
    english_level: Optional[str] = None
    daily_word_goal: int = 10
    learning_goals: Optional[dict] = None
    created_at: Optional[datetime] = None

    model_config = {"from_attributes": True}


class UserProfileUpdate(BaseModel):
    username: Optional[str] = Field(None, max_length=50)
    english_level: Optional[str] = Field(None, pattern="^(beginner|elementary|intermediate|upper_intermediate|advanced|proficient)?$")
    daily_word_goal: Optional[int] = Field(None, ge=5, le=100)
    learning_goals: Optional[dict] = None


class UserProfileResponse(BaseModel):
    """User profile kết hợp với dashboard stats."""
    id: str
    email: str
    username: Optional[str] = None
    is_premium: bool = False
    english_level: Optional[str] = None
    daily_word_goal: int = 10
    learning_goals: Optional[dict] = None
    created_at: Optional[datetime] = None
    # Dashboard stats
    streak: int = 0
    xp: int = 0
    gems: int = 0
    level: int = 0
    level_title: str = "Mầm non"

    model_config = {"from_attributes": True}


class AuthResponse(BaseModel):
    access_token: str
    user: UserResponse


# ─── Vocabulary Schemas ──────────────────────────────────────────────

class VocabularyCreate(BaseModel):
    word: str = Field(..., max_length=100)
    meaning: str = Field(..., max_length=200)
    example: Optional[str] = None
    topic: Optional[str] = Field(default="general", max_length=50)


class VocabularyUpdate(BaseModel):
    word: Optional[str] = Field(None, max_length=100)
    meaning: Optional[str] = Field(None, max_length=200)
    example: Optional[str] = None
    topic: Optional[str] = Field(None, max_length=50)


class VocabularyResponse(BaseModel):
    id: str
    user_id: str
    word: str
    meaning: str
    example: Optional[str] = None
    topic: str = "general"
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    model_config = {"from_attributes": True}


# ─── Quiz Category Schemas ───────────────────────────────────────────

class QuizCategoryResponse(BaseModel):
    id: str
    title: str
    description: Optional[str] = None
    icon: Optional[str] = None

    model_config = {"from_attributes": True}


# ─── Quiz Generation & Submission Schemas ────────────────────────────

class QuizGenerateRequest(BaseModel):
    count: int = Field(default=5, ge=1, le=50)
    skill_type: Optional[str] = Field(default=None, pattern="^(listening|reading|vocabulary|grammar)?$")
    topic: Optional[str] = Field(default=None, max_length=50)


class QuizQuestion(BaseModel):
    question: str
    options: List[str]
    correctAnswer: str
    vocabId: str


class QuizGenerateResponse(BaseModel):
    questions: List[QuizQuestion]
    total: int


class QuizAnswer(BaseModel):
    question: str
    options: List[str]
    selected: str
    correct_answer: str
    vocab_id: str
    is_correct: bool = False


class QuizSubmit(BaseModel):
    quiz_type: str = Field(default="default", max_length=50)
    skill_type: Optional[str] = Field(default=None, pattern="^(listening|reading|vocabulary|grammar)?$")
    topic: Optional[str] = Field(default=None, max_length=50)
    answers: List[QuizAnswer]


class QuizResultResponse(BaseModel):
    id: str
    quiz_type: str
    skill_type: Optional[str] = None
    topic: Optional[str] = None
    total_questions: int
    correct_answers: int
    score_percent: float
    completed_at: Optional[datetime] = None
    details: Any = None

    model_config = {"from_attributes": True}


# ─── Spaced Repetition Schemas ──────────────────────────────────────

class ReviewRequest(BaseModel):
    """Gửi kết quả review từ vựng — quality 0-5 theo SM-2."""
    quality: int = Field(..., ge=0, le=5, description="0=quên hoàn toàn, 5=nhớ hoàn hảo")


# ─── Dashboard Schemas — Mở rộng ────────────────────────────────────

class DashboardStatsVocab(BaseModel):
    id: str
    word: str
    meaning: str
    topic: str
    created_at: Optional[datetime] = None

    model_config = {"from_attributes": True}


class DashboardStatsQuiz(BaseModel):
    id: str
    quiz_type: str
    total_questions: int
    correct_answers: int
    score_percent: float
    completed_at: Optional[datetime] = None

    model_config = {"from_attributes": True}


class TodayReviewItem(BaseModel):
    """Một từ cần ôn tập hôm nay."""
    id: str
    word: str
    meaning: str
    example: Optional[str] = None
    topic: str
    review_count: int
    ease_factor: float
    created_at: Optional[datetime] = None


class TodayReviewResponse(BaseModel):
    """Danh sách từ cần ôn hôm nay."""
    total: int = 0
    completed: int = 0
    words: List[TodayReviewItem] = []


class TopicProgressItem(BaseModel):
    """Tiến độ học tập theo chủ đề."""
    topic: str
    total: int = 0
    mastered: int = 0
    accuracy: float = 0.0


class TopicProgressResponse(BaseModel):
    topics: List[TopicProgressItem] = []


# ─── Skills Schema (Migii TOPIK inspired) ──────────────────────────

class SkillItem(BaseModel):
    """Một kỹ năng: Nghe hiểu, Đọc hiểu, Từ vựng, Ngữ pháp."""
    type: str                                             # listening | reading | vocabulary | grammar
    title: str
    accuracy: float = 0.0                                 # % chính xác
    xp: int = 0                                           # XP tích luỹ
    completed: int = 0                                    # Số bài đã làm
    total: int = 0                                        # Tổng số bài


class SkillsResponse(BaseModel):
    skills: List[SkillItem] = []


class WeeklyActivityDay(BaseModel):
    """Hoạt động trong 1 ngày."""
    date: str          # "2026-06-30"
    xp: int = 0
    quizzes: int = 0
    learned: int = 0


class WeeklyActivityResponse(BaseModel):
    days: List[WeeklyActivityDay] = []


class UserStatsResponse(BaseModel):
    """Thống kê tổng quan cho header dashboard."""
    streak: int = 0
    xp: int = 0
    gems: int = 0
    level: int = 0
    level_title: str = "Mầm non"
    vocab_count: int = 0
    quiz_count: int = 0
    correct_answers: int = 0
    accuracy_rate: float = 0.0
    weekly_progress: int = 0           # % hoàn thành mục tiêu tuần


class DashboardResponse(BaseModel):
    """Mở rộng — gộp tất cả thông tin cho homepage."""
    # Header
    streak: int = 0
    xp: int = 0
    gems: int = 0
    level: int = 0
    level_title: str = "Mầm non"
    weekly_progress: int = 0

    # Stats
    vocab_count: int = 0
    quiz_count: int = 0
    correct_answers: int = 0
    accuracy_rate: float = 0.0

    # Recent activity
    recent_vocabs: List[DashboardStatsVocab] = []
    recent_quizzes: List[DashboardStatsQuiz] = []


# ─── Mock Test Schemas ───────────────────────────────────────────────

class MockTestGenerateRequest(BaseModel):
    level: str = Field(default="intermediate", pattern="^(beginner|intermediate|advanced)$")
    topic: Optional[str] = Field(default=None, max_length=50)


class MockTestQuestion(BaseModel):
    question: str
    options: List[str]
    correctAnswer: str
    difficulty: Optional[str] = None        # easy | medium | hard
    question_type: Optional[str] = None     # meaning_match | fill_blank | definition_match


class MockTestGenerateResponse(BaseModel):
    id: str
    level: str
    questions: List[MockTestQuestion]
    total: int
    duration_minutes: int = 30


class MockTestAnswer(BaseModel):
    question: str
    options: List[str]
    selected: str
    correct_answer: str
    is_correct: bool = False


class MockTestSubmit(BaseModel):
    test_id: str
    answers: List[MockTestAnswer]


class MockTestResultResponse(BaseModel):
    id: str
    test_level: str
    total_questions: int
    correct_answers: int
    score_percent: float
    grade: str = "C"
    topic: Optional[str] = None
    details: Any = None
    completed_at: Optional[datetime] = None


class MockTestHistoryItem(BaseModel):
    id: str
    test_level: str
    total_questions: int
    correct_answers: int
    score_percent: float
    grade: str
    completed_at: Optional[datetime] = None


# ─── Gamification Schemas ────────────────────────────────────────────

class RecordActivityRequest(BaseModel):
    """Ghi nhận hoạt động học tập."""
    activity_type: str = Field(..., pattern="^(learn|review|quiz|streak_claim)$")
    """Loại hoạt động: learn (học mới), review (ôn tập), quiz (làm quiz), streak_claim (nhận thưởng streak)."""
    xp_earned: int = Field(default=0, ge=0)
    metadata: Optional[dict] = None


class RecordActivityResponse(BaseModel):
    """Kết quả sau khi ghi nhận hoạt động."""
    xp_total: int = 0
    streak: int = 0
    current_level: int = 0
    level_title: str = "Mầm non"
    gems_earned: int = 0
    gems_total: int = 0
    streak_frozen: bool = False
    new_achievements: List[dict] = []


class AchievementResponse(BaseModel):
    """Một thành tựu."""
    id: str
    achievement_key: str
    title: str
    description: Optional[str] = None
    icon: Optional[str] = None
    unlocked_at: Optional[datetime] = None


class LeaderboardEntry(BaseModel):
    """Một dòng trong bảng xếp hạng."""
    rank: int
    user_id: str
    username: str
    xp: int
    streak: int


class LeaderboardResponse(BaseModel):
    entries: List[LeaderboardEntry] = []


class ClaimStreakResponse(BaseModel):
    """Kết quả nhận thưởng streak."""
    streak: int
    reward_gems: int
    reward_xp: int
    message: str
    new_achievement: Optional[AchievementResponse] = None


# ─── Pagination ──────────────────────────────────────────────────────

class PaginatedResponse(BaseModel):
    items: List[Any]
    total: int
    page: int
    pages: int
    limit: int


# ─── Seed Vocabulary Schemas ─────────────────────────────────────────

class SeedTopicItem(BaseModel):
    lesson_id: int
    title: str
    icon: str
    description: str
    count: int


class SeedVocabItem(BaseModel):
    word: str
    meaning: str
    example: Optional[str] = None
    pronunciation: Optional[str] = None
    topic: str
    lesson_id: int
