-- ============================================================
-- Tạo bảng cho Ứng dụng Học Từ Vựng Tiếng Anh
-- Chạy script này trong Supabase SQL Editor
-- ============================================================

-- Users
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  username TEXT,
  is_premium BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Vocabulary (có SM-2 fields)
CREATE TABLE IF NOT EXISTS vocabularies (
  id TEXT PRIMARY KEY,
  user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
  word TEXT NOT NULL,
  meaning TEXT NOT NULL,
  example TEXT,
  pronunciation TEXT,
  topic TEXT DEFAULT 'general',
  lesson_id INT,
  next_review_date DATE,
  ease_factor FLOAT DEFAULT 2.5,
  review_count INT DEFAULT 0,
  times_correct INT DEFAULT 0,
  times_wrong INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_vocab_user ON vocabularies(user_id);
CREATE INDEX IF NOT EXISTS idx_vocab_review ON vocabularies(user_id, next_review_date);

-- Quiz Results
CREATE TABLE IF NOT EXISTS quiz_results (
  id TEXT PRIMARY KEY,
  user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
  quiz_type TEXT NOT NULL,
  skill_type TEXT,
  total_questions INT NOT NULL,
  correct_answers INT NOT NULL,
  score_percent DECIMAL(5,2) NOT NULL,
  answers JSONB DEFAULT '[]',
  completed_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_quiz_user ON quiz_results(user_id);

-- Quiz Categories
CREATE TABLE IF NOT EXISTS quiz_categories (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  icon TEXT
);

-- Mock Tests (Kiểm tra tổng hợp)
CREATE TABLE IF NOT EXISTS mock_tests (
  id TEXT PRIMARY KEY,
  user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
  test_level TEXT NOT NULL,
  total_questions INT NOT NULL,
  correct_answers INT NOT NULL,
  score_percent DECIMAL(5,2) NOT NULL,
  grade VARCHAR(5),
  topic TEXT,
  answers JSONB DEFAULT '[]',
  completed_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_mock_user ON mock_tests(user_id);

-- Daily Activities (Streak + XP)
CREATE TABLE IF NOT EXISTS user_daily_activities (
  id TEXT PRIMARY KEY,
  user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
  activity_date DATE NOT NULL,
  xp_earned INT DEFAULT 0,
  vocab_learned INT DEFAULT 0,
  vocab_reviewed INT DEFAULT 0,
  quiz_done INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_activity_user ON user_daily_activities(user_id, activity_date);

-- Achievements
CREATE TABLE IF NOT EXISTS user_achievements (
  id TEXT PRIMARY KEY,
  user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
  achievement_key TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  icon TEXT,
  unlocked_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_achievement_user ON user_achievements(user_id);
