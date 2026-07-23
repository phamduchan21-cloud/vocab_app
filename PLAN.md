# 📚 Ứng dụng Học Từ Vựng Tiếng Anh — PLAN CHI TIẾT

> **Ngày cập nhật:** 23/07/2026
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
13. [Lộ trình nâng cấp sản phẩm](#13-lộ-trình-nâng-cấp-sản-phẩm)

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

---

## 13. Lộ trình nâng cấp sản phẩm

### 13.1 Mục tiêu

Nâng SolVocab từ ứng dụng học từ vựng cơ bản thành nền tảng học cá nhân hóa, có phản hồi phát âm, học cộng đồng, vận hành ổn định trên web/mobile và hỗ trợ học khi mất mạng.

### 13.2 Nguyên tắc triển khai

- Triển khai theo từng lát cắt hoàn chỉnh: Database → Backend → Frontend → Test → Monitoring.
- Ưu tiên dữ liệu học tập và thuật toán đề xuất trước các tính năng xã hội.
- Tất cả dữ liệu cá nhân, bản ghi âm và hoạt động xã hội phải có quyền riêng tư rõ ràng.
- Tính năng offline dùng mô hình `offline-first`, mọi thay đổi có mã định danh và thời gian cập nhật để đồng bộ an toàn.
- Mỗi giai đoạn phải có feature flag, migration có thể rollback và chỉ số đo lường kết quả.

### 13.3 Thứ tự ưu tiên

| Ưu tiên | Hạng mục | Lý do |
|:------:|----------|-------|
| **P0** | CI/CD, kiểm thử và giám sát lỗi | Tạo nền tảng an toàn trước khi mở rộng hệ thống |
| **P1** | Đề xuất theo lịch sử sai và thời điểm sắp quên | Tận dụng dữ liệu hiện có, tác động trực tiếp đến hiệu quả học |
| **P1** | Nhận diện phát âm và phản hồi âm vị | Bổ sung kỹ năng còn thiếu, tạo khác biệt cho sản phẩm |
| **P2** | Mobile offline và đồng bộ lại | Mở rộng khả năng sử dụng, cần API và dữ liệu đủ ổn định |
| **P2** | Leaderboard, nhóm học và chia sẻ | Tăng giữ chân người dùng nhưng cần kiểm soát riêng tư |

### 13.4 Giai đoạn 0 — Chuẩn hóa nền tảng kỹ thuật

**Mục tiêu:** Có pipeline tự động và khả năng phát hiện lỗi trước khi phát triển tính năng lớn.

**Công việc:**

- [ ] Tách cấu hình `development`, `staging`, `production`; không commit secret.
- [ ] Thêm backend test bằng `pytest`, `pytest-asyncio` cho auth, vocabulary, SM-2, quiz và permission.
- [ ] Thêm Flutter unit test cho model/service/provider và widget test cho các luồng học chính.
- [ ] Thêm integration test cho đăng ký → đăng nhập → học → quiz → xem kết quả.
- [x] Tạo GitHub Actions chạy backend test, Flutter analyze/test và build trên mỗi pull request.
- [ ] Chỉ deploy khi toàn bộ kiểm tra vượt qua; production cần bước phê duyệt thủ công.
- [ ] Tích hợp hệ thống theo dõi lỗi tập trung cho Flutter và FastAPI.
- [x] Thêm request ID, structured log và loại bỏ token/password khỏi log.
- [ ] Thiết lập health check, cảnh báo tỷ lệ lỗi API, thời gian phản hồi và lỗi đồng bộ.

**Tiến độ triển khai đợt 1 — 23/07/2026:**

- [x] Thêm `/health/live` và readiness check `/health` có kiểm tra database.
- [x] Thêm header `X-Request-ID` và log JSON cho request backend.
- [x] Thêm `pytest`, `pytest-asyncio`, coverage và test health/SM-2.
- [x] Thêm CI cho backend test, Flutter analyze, Flutter test và build web.
- [x] Thêm workflow deploy Vercel thủ công cho preview/production.
- [x] Viết hướng dẫn cấu hình CI/CD và rollback tại `docs/CI_CD.md`.
- [ ] Cấu hình GitHub Environments, secrets và required reviewer trên repository.
- [ ] Mở rộng backend test đến coverage tối thiểu 70%.
- [ ] Bổ sung integration test toàn bộ luồng đăng nhập và học.
- [ ] Kết nối dịch vụ giám sát lỗi tập trung và thiết lập cảnh báo.

**Pipeline đề xuất:**

```text
Pull Request
    → Backend lint + test
    → Flutter analyze + test
    → Build web/APK
    → Deploy staging
    → Smoke test
    → Phê duyệt
    → Deploy production
    → Health check + thông báo kết quả
```

**Tiêu chí nghiệm thu:**

- Pull request lỗi không thể merge.
- Backend service cốt lõi đạt coverage tối thiểu 70%.
- Luồng đăng nhập và học chính có integration test.
- Lỗi production có stack trace, phiên bản ứng dụng và request ID.
- Có tài liệu rollback cho frontend, backend và database migration.

### 13.5 Giai đoạn 1 — Đề xuất học tập cá nhân hóa

**Mục tiêu:** Chọn đúng từ người dùng cần học dựa trên lịch sử sai, độ khó và nguy cơ quên.

**Dữ liệu cần bổ sung:**

- `learning_events`: `user_id`, `vocabulary_id`, `activity_type`, `is_correct`, `response_time_ms`, `occurred_at`.
- `review_states`: `next_review_at`, `interval_days`, `ease_factor`, `lapse_count`, `last_quality`.
- `recommendation_snapshots`: danh sách đề xuất, điểm số, lý do và phiên bản thuật toán.

**Công việc:**

- [ ] Chuẩn hóa sự kiện từ Flashcard, Quiz, Mini Test và Listening vào một bảng lịch sử.
- [ ] Xây dựng `RecommendationService` để tính điểm ưu tiên theo công thức có thể giải thích.
- [ ] Ưu tiên từ quá hạn, sắp quên, sai nhiều, phản hồi chậm và chưa thành thạo.
- [ ] Giới hạn lặp từ trong một phiên và cân bằng theo chủ đề/độ khó.
- [ ] Trả về lý do đề xuất như “Bạn đã sai 3 lần” hoặc “Sắp đến hạn ôn”.
- [ ] Tạo endpoint xem trước phiên học và endpoint ghi nhận phản hồi.
- [ ] Theo dõi tỷ lệ hoàn thành, tỷ lệ nhớ lại và số từ quá hạn.

**Công thức khởi đầu:**

```text
priority_score =
    overdue_score
  + wrong_history_score
  + forgetting_risk_score
  + slow_response_score
  + learning_goal_score
  - recent_repetition_penalty
```

Giai đoạn đầu dùng luật có trọng số để dễ kiểm thử và giải thích. Chỉ cân nhắc machine learning khi đã có đủ dữ liệu sạch và có baseline để so sánh.

**API dự kiến:**

| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | `/api/recommendations/session` | Tạo danh sách học cá nhân hóa |
| POST | `/api/recommendations/events` | Ghi nhận kết quả học |
| GET | `/api/recommendations/explanations/{vocabulary_id}` | Giải thích lý do đề xuất |

**Tiêu chí nghiệm thu:**

- Không đề xuất từ đã học ngay trước đó nếu chưa đến lượt.
- Từ sai nhiều hoặc quá hạn xuất hiện sớm hơn từ mới.
- API trả kết quả ổn định khi người dùng chưa có lịch sử.
- Có unit test cho từng thành phần điểm và test chống trùng câu hỏi.

### 13.6 Giai đoạn 2 — Nhận diện phát âm và phản hồi theo âm vị

**Mục tiêu:** Người dùng đọc từ/câu tiếng Anh và nhận phản hồi cụ thể đến từng âm vị thay vì chỉ có điểm tổng.

**Luồng chức năng:**

```text
Người dùng nghe mẫu
    → Ghi âm
    → Chuẩn hóa âm thanh
    → Speech-to-text + căn chỉnh âm vị
    → So sánh phát âm mục tiêu
    → Điểm tổng + âm đúng/sai + hướng dẫn luyện lại
```

**Công việc:**

- [ ] Xin quyền micro rõ ràng và hiển thị trạng thái đang ghi âm.
- [ ] Chuẩn hóa định dạng âm thanh, giới hạn thời lượng và dung lượng tải lên.
- [ ] Tạo `PronunciationService` độc lập với nhà cung cấp nhận diện giọng nói.
- [ ] Lưu IPA mục tiêu và kết quả căn chỉnh âm vị theo từ.
- [ ] Chấm các nhóm: độ chính xác âm vị, trọng âm, độ trôi chảy và mức hoàn thành.
- [ ] Highlight âm vị cần sửa, phát lại mẫu và cho phép ghi âm lại.
- [ ] Không lưu file ghi âm mặc định; nếu lưu để xem lại phải có sự đồng ý.
- [ ] Xóa file tạm sau khi xử lý và không ghi URL âm thanh vào log.
- [ ] Xây bộ dữ liệu kiểm thử gồm giọng đọc đúng, sai phổ biến và môi trường có nhiễu.

**Dữ liệu dự kiến:**

- `pronunciation_attempts`: từ/câu mục tiêu, transcript, điểm, thời lượng, thời điểm.
- `phoneme_feedback`: âm vị mục tiêu, âm vị nhận diện, vị trí, mức tin cậy, gợi ý.
- `audio_consent`: lựa chọn lưu/không lưu bản ghi và thời hạn lưu.

**API dự kiến:**

| Method | Endpoint | Mô tả |
|--------|----------|-------|
| POST | `/api/pronunciation/evaluate` | Gửi âm thanh để chấm phát âm |
| GET | `/api/pronunciation/history` | Xem lịch sử luyện phát âm |
| DELETE | `/api/pronunciation/attempts/{id}` | Xóa dữ liệu một lần luyện |

**Tiêu chí nghiệm thu:**

- Phản hồi hiển thị được âm vị sai và gợi ý sửa bằng tiếng Việt.
- File không hợp lệ, quá lớn hoặc không có tiếng nói được xử lý thân thiện.
- Bản ghi không được lưu khi người dùng chưa đồng ý.
- Độ trễ mục tiêu dưới 5 giây cho một từ ngắn trong điều kiện mạng bình thường.

### 13.7 Giai đoạn 3 — Mobile offline và đồng bộ

**Mục tiêu:** Đóng gói Android/iOS, cho phép học bộ bài đã tải khi mất mạng và đồng bộ an toàn khi có mạng lại.

**Công việc:**

- [ ] Chuẩn hóa responsive và quyền hệ thống cho Android/iOS.
- [ ] Đóng gói bản Android nội bộ trước, sau đó mới hoàn thiện iOS.
- [ ] Lưu cục bộ chủ đề, từ vựng, flashcard, lịch ôn và draft Mini Test.
- [ ] Tạo `sync_queue` cho thao tác phát sinh offline.
- [ ] Mỗi thao tác có `operation_id` để backend xử lý idempotent.
- [ ] Dùng `updated_at`, `version` và tombstone cho bản ghi xóa.
- [ ] Hiển thị rõ trạng thái offline, đang đồng bộ và lỗi cần thử lại.
- [ ] Retry theo exponential backoff, không retry vô hạn với lỗi dữ liệu.
- [ ] Mã hóa dữ liệu nhạy cảm tại thiết bị và không cache token trong vùng không an toàn.
- [ ] Kiểm thử mất mạng giữa lúc làm bài, tắt app, đăng nhập lại và đổi thiết bị.

**Chiến lược xung đột:**

| Loại dữ liệu | Cách xử lý |
|--------------|------------|
| Kết quả học/sự kiện | Append-only, không ghi đè |
| Trạng thái SM-2 | Backend tính lại theo chuỗi sự kiện |
| Bookmark | Bản cập nhật mới nhất thắng |
| Ghi chú cá nhân | Báo xung đột nếu cả hai phía cùng sửa |
| Bản ghi đã xóa | Tombstone thắng dữ liệu cũ |

**Tiêu chí nghiệm thu:**

- Người dùng hoàn thành được phiên Flashcard đã tải khi không có mạng.
- Đóng/mở app không làm mất hàng đợi đồng bộ.
- Gửi lại cùng một thao tác không tạo dữ liệu trùng.
- Sau khi có mạng, dữ liệu hội tụ giữa mobile, backend và web.

### 13.8 Giai đoạn 4 — Leaderboard, nhóm học và chia sẻ có quyền riêng tư

**Mục tiêu:** Tạo động lực xã hội nhưng người dùng kiểm soát được dữ liệu nào được công khai.

**Mặc định riêng tư:**

- Hồ sơ, lịch sử học và thành tích mặc định là riêng tư.
- Leaderboard dùng tên hiển thị, không dùng email.
- Người dùng chọn phạm vi: `private`, `friends`, `group`, `public`.
- Tham gia nhóm và xuất hiện trên bảng xếp hạng phải là opt-in.
- Có chặn người dùng, báo cáo nội dung và rời nhóm.

**Công việc:**

- [ ] Leaderboard tuần/tháng theo XP với snapshot để tránh truy vấn nặng.
- [ ] Tạo nhóm bằng mã mời hoặc phê duyệt thành viên.
- [ ] Vai trò `owner`, `moderator`, `member`; kiểm tra quyền ở backend.
- [ ] Thử thách nhóm có mục tiêu, thời gian và phần thưởng giới hạn.
- [ ] Chia sẻ thành tích bằng ảnh thẻ/tem, không để lộ email hoặc dữ liệu học chi tiết.
- [ ] Trang cài đặt quyền riêng tư và chức năng xóa dữ liệu xã hội.
- [ ] Rate limit hành động mời, theo dõi và chia sẻ.
- [ ] Audit log cho thay đổi quyền nhóm và xử lý báo cáo.

**Bảng dữ liệu dự kiến:**

- `groups`, `group_members`, `group_invites`.
- `leaderboard_snapshots`, `leaderboard_entries`.
- `privacy_settings`, `friendships`, `blocked_users`.
- `shared_achievements`, `content_reports`, `moderation_actions`.

**Tiêu chí nghiệm thu:**

- Người lạ không xem được hồ sơ riêng tư qua UI hoặc gọi API trực tiếp.
- Người dùng có thể rời bảng xếp hạng và xóa bài chia sẻ.
- Chỉ chủ nhóm/người kiểm duyệt được quản lý thành viên.
- Bảng xếp hạng có quy tắc chống gian lận và giới hạn XP bất thường.

### 13.9 Kế hoạch phát hành dự kiến

| Mốc | Thời lượng ước tính | Kết quả bàn giao |
|-----|:------------------:|------------------|
| **M0 — Foundation** | 2 tuần | CI/CD, test nền, staging, monitoring |
| **M1 — Smart Review** | 3 tuần | Lịch sử học hợp nhất và đề xuất cá nhân hóa |
| **M2 — Pronunciation MVP** | 4 tuần | Ghi âm, chấm từ đơn, phản hồi âm vị |
| **M3 — Offline Android** | 4 tuần | APK nội bộ, tải bộ học, sync queue |
| **M4 — Social Safe** | 4 tuần | Leaderboard, nhóm học, chia sẻ riêng tư |
| **M5 — Hardening** | 2 tuần | Tối ưu, kiểm thử tải, bảo mật và phát hành |

Tổng thời gian ước tính: **19 tuần** với một nhóm nhỏ. Các mốc có thể chạy song song khi backend, Flutter và QA có người phụ trách độc lập.

### 13.10 Chỉ số theo dõi

| Nhóm | Chỉ số |
|------|--------|
| Học tập | Tỷ lệ nhớ lại sau 7/30 ngày, số từ quá hạn, tỷ lệ hoàn thành phiên |
| Phát âm | Số lần luyện, tỷ lệ luyện lại, mức cải thiện điểm theo âm vị |
| Giữ chân | D1/D7/D30 retention, streak, số phiên học mỗi tuần |
| Xã hội | Tỷ lệ opt-in, nhóm hoạt động, báo cáo vi phạm, tỷ lệ rời nhóm |
| Kỹ thuật | Crash-free sessions, API error rate, p95 latency, sync failure rate |

### 13.11 Definition of Done chung

- [ ] Database migration có script nâng cấp và rollback.
- [ ] Endpoint có auth, permission, `response_model` và API test.
- [ ] Frontend đủ Loading, Error, Empty và Data state.
- [ ] Có unit test cho business logic và integration test cho luồng chính.
- [ ] Có log/metric nhưng không chứa secret hoặc dữ liệu nhạy cảm.
- [ ] Có kiểm tra accessibility và responsive.
- [ ] Tài liệu API, cấu hình môi trường và hướng dẫn vận hành được cập nhật.
- [ ] Tính năng được kiểm thử trên staging trước khi bật production.
