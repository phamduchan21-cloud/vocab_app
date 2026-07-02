from datetime import datetime, date

from sqlalchemy import (
    Column,
    String,
    Integer,
    Boolean,
    DateTime,
    Date,
    ForeignKey,
    DECIMAL,
    Text,
    JSON,
    Float,
)
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(String(36), primary_key=True)  # UUID lưu dạng string
    email = Column(String(100), unique=True, nullable=False)
    username = Column(String(50), nullable=True)
    is_premium = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    vocabularies = relationship("Vocabulary", back_populates="user", lazy="select")
    quiz_results = relationship("QuizResult", back_populates="user", lazy="select")
    daily_activities = relationship("UserDailyActivity", back_populates="user", lazy="select")
    achievements = relationship("UserAchievement", back_populates="user", lazy="select")

    def __repr__(self):
        return f"<User(id={self.id}, email={self.email})>"


class Vocabulary(Base):
    __tablename__ = "vocabularies"

    id = Column(String(36), primary_key=True)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    word = Column(String(100), nullable=False)
    meaning = Column(String(200), nullable=False)
    example = Column(Text, nullable=True)
    topic = Column(String(50), default="general")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # ─── Spaced Repetition (SM-2) fields ─────────────────────────────
    next_review_date = Column(Date, nullable=True, default=None)   # Ngày cần ôn tiếp theo
    ease_factor = Column(Float, default=2.5)                        # SM-2 ease factor (mặc định 2.5)
    review_count = Column(Integer, default=0)                       # Số lần đã ôn
    times_correct = Column(Integer, default=0)                      # Số lần trả lời đúng
    times_wrong = Column(Integer, default=0)                        # Số lần trả lời sai

    user = relationship("User", back_populates="vocabularies")

    def __repr__(self):
        return f"<Vocabulary(id={self.id}, word={self.word})>"


class QuizResult(Base):
    __tablename__ = "quiz_results"

    id = Column(String(36), primary_key=True)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    quiz_type = Column(String(50), nullable=False)
    skill_type = Column(String(20), nullable=True, default=None)  # listening | reading | vocabulary | grammar
    total_questions = Column(Integer, nullable=False)
    correct_answers = Column(Integer, nullable=False)
    score_percent = Column(DECIMAL(5, 2), nullable=False)
    answers = Column(JSON, default=[])
    completed_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="quiz_results")

    def __repr__(self):
        return f"<QuizResult(id={self.id}, score={self.score_percent})>"


class QuizCategory(Base):
    __tablename__ = "quiz_categories"

    id = Column(String(36), primary_key=True)
    title = Column(String(100), nullable=False)
    description = Column(String(255), nullable=True)
    icon = Column(String(50), nullable=True)

    def __repr__(self):
        return f"<QuizCategory(id={self.id}, title={self.title})>"


class UserDailyActivity(Base):
    """Ghi lại hoạt động mỗi ngày của user — dùng cho streak & XP."""
    __tablename__ = "user_daily_activities"

    id = Column(String(36), primary_key=True)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    activity_date = Column(Date, nullable=False)                           # Ngày hoạt động
    xp_earned = Column(Integer, default=0)                                 # XP kiếm được trong ngày
    vocab_learned = Column(Integer, default=0)                             # Số từ mới học
    vocab_reviewed = Column(Integer, default=0)                            # Số từ đã ôn tập
    quiz_done = Column(Integer, default=0)                                 # Số quiz đã làm
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="daily_activities")

    def __repr__(self):
        return f"<UserDailyActivity(user={self.user_id}, date={self.activity_date}, xp={self.xp_earned})>"


class UserAchievement(Base):
    """Thành tựu đạt được của user."""
    __tablename__ = "user_achievements"

    id = Column(String(36), primary_key=True)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    achievement_key = Column(String(50), nullable=False)                   # Key định danh: 'streak_7', 'streak_30', ...
    title = Column(String(100), nullable=False)                            # Tên hiển thị
    description = Column(String(255), nullable=True)                       # Mô tả
    icon = Column(String(50), nullable=True)                               # Icon
    unlocked_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="achievements")

    def __repr__(self):
        return f"<UserAchievement(user={self.user_id}, key={self.achievement_key})>"


class MockTest(Base):
    """Kết quả bài kiểm tra từ vựng tiếng Anh tổng hợp."""
    __tablename__ = "mock_tests"

    id = Column(String(36), primary_key=True)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    test_level = Column(String(20), nullable=False)                           # beginner | intermediate | advanced
    total_questions = Column(Integer, nullable=False)
    correct_answers = Column(Integer, nullable=False)
    score_percent = Column(DECIMAL(5, 2), nullable=False)
    grade = Column(String(5), nullable=True)                                   # A, B, C, D
    topic = Column(String(50), nullable=True)                                  # Chủ đề được kiểm tra
    answers = Column(JSON, default=[])
    completed_at = Column(DateTime(timezone=True), server_default=func.now())

    def __repr__(self):
        return f"<MockTest(id={self.id}, level={self.test_level}, grade={self.grade})>"
