# 📚 Ứng dụng Học Từ Vựng Tiếng Anh — PLAN CHI TIẾT

> **Ngày cập nhật:** 02/07/2026  
> **Stack:** Flutter (Web) · FastAPI (Backend) · Supabase (Database + Auth)  
> **Deploy:** Vercel (Frontend Web) · Render (Backend API)  
> **Mục tiêu:** App học từ vựng tiếng Anh với flashcard, SM-2, quiz, và gamification

---

## 🧭 Mục lục

1. [Tổng quan kiến trúc](#1-tổng-quan-kiến-trúc)
2. [6 Module chính](#2-6-module-chính)
3. [Dashboard](#3-dashboard)
4. [Từ vựng — 15 Bài](#4-từ-vựng--15-bài)
5. [Flashcard & SM-2](#5-flashcard--sm-2)
6. [Quiz trắc nghiệm](#6-quiz-trắc-nghiệm)
7. [Gamification](#7-gamification)
8. [Cấu trúc thư mục](#8-cấu-trúc-thư-mục)
9. [Database Design](#9-database-design)
10. [API Endpoints](#10-api-endpoints)
11. [Deploy Guide](#11-deploy-guide)
12. [Kế hoạch phát triển](#12-kế-hoạch-phát-triển)

---

## 1. Tổng quan kiến trúc

```
┌─────────────────────────────────────────────────────────────────┐
│                    FLUTTER WEB (Vercel)                          │
│  Screen ← Provider ← Service (HTTP) ←→ FastAPI Backend          │
│  Auth: supabase_flutter SDK                                     │
└─────────────────────────┬───────────────────────────────────────┘
                          │ REST API (JSON) · Bearer JWT
┌─────────────────────────┴───────────────────────────────────────┐
│                    FASTAPI BACKEND (Render)                      │
│  Routers → Services → SQLAlchemy ORM → Supabase PostgreSQL      │
└─────────────────────────┬───────────────────────────────────────┘
                          │
┌─────────────────────────┴───────────────────────────────────────┐
│                    SUPABASE CLOUD (Free Tier)                    │
│  PostgreSQL Database · Auth (Email/Password) · JWT Tokens       │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. 6 Module chính

| Module | Mô tả | Backend | Frontend | Trạng thái |
|--------|-------|:-------:|:--------:|:----------:|
| **Auth** | Đăng ký/đăng nhập email | ✅ | ✅ | ✅ Hoàn thành |
| **Từ vựng** | CRUD + 15 chủ đề + 430 từ | ✅ | ✅ | ✅ Hoàn thành |
| **Flashcard SM-2** | Lật thẻ + ôn tập spaced repetition | ✅ | ✅ | ✅ Hoàn thành |
| **Quiz** | Sinh câu hỏi, chấm điểm, lịch sử | ✅ | ✅ | ✅ Hoàn thành |
| **Dashboard** | Streak, XP, Level, Weekly | ✅ | ✅ | ✅ Hoàn thành |
| **Gamification** | Thành tựu, BXH, Nhận thưởng | ✅ | ⚠️ Profile | ✅ Cơ bản xong |

---

## 3. Dashboard

```
┌──────────────────────────────────────────┐
│  MeuBeu                            🔔 👤 │
├──────────────────────────────────────────┤
│  🔥 Streak  │  📊 Tuần  │  ⭐ XP  │ 💎  │  ← StreakBar
├──────────────────────────────────────────┤
│  📖 Hôm nay cần ôn: 5 từ                 │  ← ReviewCard
│  [Bắt đầu Flashcard →]                    │
├──────────────────────────────────────────┤
│  🎯 TÍNH NĂNG (Grid 2×2)                 │  ← SkillGrid
│  ┌──────────┐ ┌──────────┐              │
│  │ 📝 Từ    │ │ 🃏       │              │
│  │ vựng     │ │ Flashcard│              │
│  └──────────┘ └──────────┘              │
│  ┌──────────┐ ┌──────────┐              │
│  │ ✏️ Quiz  │ │ 🏆 Thành │              │
│  │          │ │ tựu     │              │
│  └──────────┘ └──────────┘              │
├──────────────────────────────────────────┤
│  📝 KIỂM TRA TỪ VỰNG                     │  ← MockTestCard
│  🌱 Cơ bản    10 câu · 15 phút           │
│  🔥 Nâng cao  30 câu · 45 phút           │
├──────────────────────────────────────────┤
│  🏆 BẢNG XẾP HẠNG                         │  ← Leaderboard
├──────────────────────────────────────────┤
│  🏠 Home  │  📝 Học  │  ✏️ Quiz  │  👤   │  ← Bottom Nav
└──────────────────────────────────────────┘
```

---

## 4. Từ vựng — 15 Bài

| Bài | Chủ đề | Số từ |
|:---:|--------|:-----:|
| 1 | Greetings & Introductions | 30 |
| 2 | Family & Relationships | 25 |
| 3 | Numbers, Time & Dates | 30 |
| 4 | Daily Routines | 30 |
| 5 | Food & Drinks | 35 |
| 6 | Travel & Directions | 30 |
| 7 | Shopping & Prices | 30 |
| 8 | Weather & Seasons | 25 |
| 9 | Health & Body | 30 |
| 10 | Work & Business | 35 |
| 11 | Education & School | 30 |
| 12 | Entertainment & Hobbies | 25 |
| 13 | Technology & Internet | 30 |
| 14 | Emotions & Feelings | 25 |
| 15 | Society & Culture | 30 |
| | **Tổng** | **430 từ** |

---

## 5. Flashcard & SM-2

**Cơ chế Spaced Repetition (SM-2):**
- `quality 0-2` → quên → giảm ease factor, reset interval
- `quality 3` → nhớ với khó khăn → interval nhỏ
- `quality 4-5` → nhớ tốt → tăng interval (1 → 3 → 7 → 16 → 30 ngày)
- Ease factor: tối thiểu 1.3, điều chỉnh sau mỗi review

**UI Flashcard:**
- Mặt trước: từ tiếng Anh + phiên âm
- Mặt sau: nghĩa tiếng Việt + ví dụ
- Nút "Cần ôn lại" (quality 1) hoặc "Đã thuộc" (quality 4)
- Hiển thị tiến độ: `3/15`

---

## 6. Quiz trắc nghiệm

**API:**
- `POST /api/quiz/generate` → sinh câu hỏi từ vocab của user
- `POST /api/quiz/submit` → chấm điểm, lưu kết quả
- `GET /api/quiz/history` → lịch sử làm bài

**Cấu trúc câu hỏi:**
```
Nghĩa của từ 'hello' là gì?
  A. tạm biệt
  B. xin chào ✓
  C. cảm ơn
  D. xin lỗi
```

---

## 7. Gamification

**Streak:** Đếm ngày học liên tiếp  
**XP:** 5/học từ mới · 3/ôn tập · 10/làm quiz  
**Level:** Mầm non (0) → Lá xanh (500) → Cây lớn (1500) → Cao thủ (4000) → Phiêu lưu (8000) → Huyền thoại (15000)  
**Thành tựu:** 7 ngày · 14 ngày · 30 ngày · 50 từ · 200 từ · Quiz hoàn hảo  
**Bảng xếp hạng:** Top users theo XP

---

## 8. Cấu trúc thư mục

```
D:\AppHocTuVung\
├── backend/
│   ├── main.py                # FastAPI app + routers
│   ├── database.py            # SQLAlchemy async engine
│   ├── models.py              # User, Vocabulary, QuizResult, MockTest...
│   ├── schemas.py             # Pydantic request/response
│   ├── seed_data.py           # 430 từ vựng tiếng Anh
│   ├── services/
│   │   ├── auth_service.py
│   │   ├── vocabulary_service.py   # CRUD + SM-2 + seed data
│   │   ├── quiz_service.py         # Sinh câu hỏi + chấm điểm
│   │   ├── dashboard_service.py    # Streak, XP, Level, Weekly
│   │   └── gamification_service.py # Achievements, Leaderboard
│   ├── routers/
│   │   ├── auth.py
│   │   ├── vocabulary.py
│   │   ├── quiz.py
│   │   ├── dashboard.py
│   │   ├── gamification.py
│   │   └── mock_test.py
│   ├── core/
│   │   ├── config.py
│   │   └── security.py
│   └── requirements.txt
├── frontend/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app.dart            # MaterialApp.router + Theme
│   │   ├── config/api_config.dart
│   │   ├── models/             # vocabulary, quiz_result, dashboard_data...
│   │   ├── services/           # api_service, vocabulary, quiz, dashboard
│   │   ├── providers/          # auth, vocabulary, quiz, dashboard
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   ├── dashboard_screen.dart
│   │   │   ├── vocabulary_list_screen.dart
│   │   │   ├── vocabulary_form_screen.dart
│   │   │   ├── quiz_list_screen.dart
│   │   │   ├── quiz_play_screen.dart
│   │   │   ├── quiz_result_screen.dart
│   │   │   ├── quiz_history_screen.dart
│   │   │   ├── mock_test_screen.dart
│   │   │   └── profile_screen.dart
│   │   └── widgets/
│   │       ├── streak_bar.dart
│   │       ├── review_card.dart
│   │       ├── skill_grid.dart
│   │       ├── stats_grid.dart
│   │       ├── flashcard_widget.dart
│   │       ├── vocab_card.dart
│   │       ├── question_card.dart
│   │       ├── leaderboard_preview.dart
│   │       └── loading_widget.dart
│   └── pubspec.yaml
├── ARCHITECTURE.md
├── PLAN.md
└── CLAUDE.md
```

---

## 9. Database Design

```sql
-- Người dùng
CREATE TABLE users (
  id UUID PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  username TEXT,
  is_premium BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Từ vựng (có SM-2 fields)
CREATE TABLE vocabularies (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  word TEXT NOT NULL,           -- hello
  meaning TEXT NOT NULL,        -- xin chào
  example TEXT,                 -- Hello, how are you?
  pronunciation TEXT,           -- /həˈloʊ/
  topic TEXT DEFAULT 'general', -- greetings | family | food | ...
  lesson_id INT,                -- 1-15
  next_review_date DATE,        -- SM-2: ngày ôn tiếp
  ease_factor FLOAT DEFAULT 2.5,
  review_count INT DEFAULT 0,
  times_correct INT DEFAULT 0,
  times_wrong INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Kết quả quiz
CREATE TABLE quiz_results (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  quiz_type TEXT NOT NULL,        -- vocabulary | grammar
  skill_type TEXT,                -- vocabulary
  total_questions INT NOT NULL,
  correct_answers INT NOT NULL,
  score_percent DECIMAL(5,2),
  answers JSONB DEFAULT '[]',
  completed_at TIMESTAMPTZ DEFAULT NOW()
);

-- Kiểm tra tổng hợp
CREATE TABLE mock_tests (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  test_level TEXT NOT NULL,        -- beginner | intermediate | advanced
  total_questions INT NOT NULL,
  correct_answers INT NOT NULL,
  score_percent DECIMAL(5,2),
  grade VARCHAR(5),               -- A | B | C | D
  topic TEXT,
  answers JSONB DEFAULT '[]',
  completed_at TIMESTAMPTZ DEFAULT NOW()
);

-- Hoạt động hàng ngày (streak + XP)
CREATE TABLE user_daily_activities (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  activity_date DATE NOT NULL,
  xp_earned INT DEFAULT 0,
  vocab_learned INT DEFAULT 0,
  vocab_reviewed INT DEFAULT 0,
  quiz_done INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Thành tựu
CREATE TABLE user_achievements (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  achievement_key TEXT NOT NULL,   -- streak_7 | word_50 | ...
  title TEXT NOT NULL,
  description TEXT,
  icon TEXT,
  unlocked_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 10. API Endpoints

| Method | Endpoint | Mô tả |
|--------|----------|-------|
| POST | `/api/auth/register` | Đăng ký |
| POST | `/api/auth/login` | Đăng nhập |
| GET | `/api/auth/me` | Thông tin user |
| GET | `/api/vocabularies` | Danh sách từ vựng |
| POST | `/api/vocabularies` | Thêm từ mới |
| GET | `/api/vocabularies/{id}` | Chi tiết từ |
| PUT | `/api/vocabularies/{id}` | Cập nhật từ |
| DELETE | `/api/vocabularies/{id}` | Xoá từ |
| PUT | `/api/vocabularies/{id}/review` | SM-2 review |
| GET | `/api/vocabularies/lessons` | 15 bài từ vựng |
| GET | `/api/vocabularies/grammar` | Ngữ pháp |
| GET | `/api/vocabularies/advanced` | Giáo trình nâng cao |
| POST | `/api/quiz/generate` | Sinh quiz |
| POST | `/api/quiz/submit` | Nộp quiz |
| GET | `/api/quiz/history` | Lịch sử quiz |
| GET | `/api/dashboard` | Dashboard stats |
| GET | `/api/dashboard/skills` | Kỹ năng |
| GET | `/api/dashboard/today-review` | Từ cần ôn hôm nay |
| GET | `/api/dashboard/topic-progress` | Tiến độ chủ đề |
| GET | `/api/dashboard/weekly-activity` | Hoạt động tuần |
| POST | `/api/gamification/activity` | Ghi nhận activity |
| GET | `/api/gamification/achievements` | Thành tựu |
| GET | `/api/gamification/leaderboard` | Bảng xếp hạng |
| POST | `/api/gamification/claim-streak` | Nhận thưởng streak |
| POST | `/api/mock-tests/generate` | Tạo bài kiểm tra |
| POST | `/api/mock-tests/submit` | Nộp bài kiểm tra |
| GET | `/api/mock-tests/history` | Lịch sử kiểm tra |

---

## 11. Deploy Guide

### Backend → Render

1. Push code lên GitHub
2. Render Dashboard: New Web Service → Connect repo
3. **Build:** `pip install -r backend/requirements.txt`
4. **Start:** `uvicorn main:app --host 0.0.0.0 --port $PORT`
5. **Root Directory:** `backend/`
6. **Env vars:**
   - `SUPABASE_URL` — từ Supabase Project Settings
   - `SUPABASE_ANON_KEY` — từ Supabase Project Settings
   - `SUPABASE_JWT_SECRET` — từ Supabase JWT Settings
   - `DATABASE_URL` — Supabase PostgreSQL connection string
7. Kết quả: `https://vocab-api.onrender.com/docs` ✅

### Frontend → Vercel

1. Vercel Dashboard: Add New Project → Import GitHub repo
2. **Framework Preset:** Other
3. **Build:** `cd frontend && flutter build web --release`
4. **Output:** `frontend/build/web`
5. **Env:** `API_BASE_URL=https://vocab-api.onrender.com`
6. Kết quả: `https://vocab-app.vercel.app` ✅

---

## 12. Kế hoạch phát triển

| Phase | Nội dung | Trạng thái |
|-------|----------|:----------:|
| **1** | Backend Core (Auth, Vocabulary, Quiz, Dashboard) | ✅ |
| **2** | Backend Gamification + Mock Test | ✅ |
| **3** | Frontend Auth + Dashboard | ✅ |
| **4** | Frontend Vocabulary + Flashcard | ✅ |
| **5** | Frontend Quiz + Mock Test | ✅ |
| **6** | Deploy (Vercel + Render) | ⏳ |
| **7** | Tối ưu & Hoàn thiện | ⏳ |

### Mục tiêu sắp tới

- [x] Dọn dẹp code (bỏ Listening/Reading/Speaking)
- [x] Thêm 430 từ vựng tiếng Anh seed data
- [x] Flashcard widget với SM-2
- [ ] Deploy backend lên Render
- [ ] Deploy frontend lên Vercel
- [ ] Thêm chức năng "Chọn chủ đề" trước khi quiz
- [ ] Thêm timer 30s cho quiz
