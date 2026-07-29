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
  english_level TEXT,
  learning_goals JSONB,
  daily_word_goal INT NOT NULL DEFAULT 10,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Vocabulary (có SM-2 fields)
CREATE TABLE IF NOT EXISTS vocabularies (
  id TEXT PRIMARY KEY,
  user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
  word TEXT NOT NULL,
  meaning TEXT NOT NULL,
  example TEXT,
  personal_note TEXT,
  pronunciation TEXT,
  topic TEXT DEFAULT 'general',
  lesson_id INT,
  next_review_date DATE,
  ease_factor FLOAT DEFAULT 2.5,
  review_count INT DEFAULT 0,
  review_interval INT DEFAULT 0,
  times_correct INT DEFAULT 0,
  times_wrong INT DEFAULT 0,
  is_bookmarked BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_vocab_user ON vocabularies(user_id);
CREATE INDEX IF NOT EXISTS idx_vocab_review ON vocabularies(user_id, next_review_date);
CREATE INDEX IF NOT EXISTS idx_vocab_bookmark ON vocabularies(user_id, is_bookmarked);

-- Quiz Results
CREATE TABLE IF NOT EXISTS quiz_results (
  id TEXT PRIMARY KEY,
  user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
  quiz_type TEXT NOT NULL,
  skill_type TEXT,
  topic TEXT,
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

-- Claimable rewards, persisted wallet, and immutable ledger
CREATE TABLE IF NOT EXISTS user_rewards (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reward_key TEXT NOT NULL,
  source_type TEXT NOT NULL DEFAULT 'achievement',
  title TEXT NOT NULL,
  description TEXT,
  xp_amount INT NOT NULL DEFAULT 0,
  gems_amount INT NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'pending',
  unlocked_at TIMESTAMPTZ DEFAULT NOW(),
  claimed_at TIMESTAMPTZ,
  CONSTRAINT uq_user_reward_key UNIQUE (user_id, reward_key)
);

CREATE INDEX IF NOT EXISTS idx_user_reward_status
  ON user_rewards(user_id, status);

CREATE TABLE IF NOT EXISTS user_wallets (
  user_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  gems_balance INT NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS reward_transactions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  transaction_key TEXT NOT NULL,
  source_type TEXT NOT NULL,
  source_id TEXT,
  xp_delta INT NOT NULL DEFAULT 0,
  gems_delta INT NOT NULL DEFAULT 0,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT uq_reward_transaction_key UNIQUE (user_id, transaction_key)
);

CREATE INDEX IF NOT EXISTS idx_reward_transaction_user
  ON reward_transactions(user_id, created_at);

-- CEFR A1-B2 learning route
CREATE TABLE IF NOT EXISTS user_learning_paths (
  user_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  current_cefr TEXT NOT NULL DEFAULT 'A1',
  current_step INT NOT NULL DEFAULT 0,
  placement_source TEXT NOT NULL DEFAULT 'onboarding',
  started_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_path_steps (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  cefr_level TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'locked',
  progress_percent FLOAT NOT NULL DEFAULT 0,
  quiz_average FLOAT NOT NULL DEFAULT 0,
  mini_test_score FLOAT NOT NULL DEFAULT 0,
  completed_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT uq_user_path_step UNIQUE (user_id, cefr_level)
);

CREATE INDEX IF NOT EXISTS idx_user_path_step_status
  ON user_path_steps(user_id, status);
