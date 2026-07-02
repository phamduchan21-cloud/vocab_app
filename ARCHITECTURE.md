# 🏗 Kiến trúc & Quy tắc — Ứng dụng Học Từ Vựng

> **Ngày cập nhật:** 29/06/2026  
> **Stack:** Flutter 3.44 · FastAPI · Supabase (PostgreSQL + Auth)  
> **Deploy:** Render (BE) · Vercel (FE Web) · Android APK

---

## 📑 Mục lục

1. [Tổng quan kiến trúc](#1-tổng-quan-kiến-trúc)
2. [Backend — FastAPI](#2-backend--fastapi)
3. [Frontend — Flutter](#3-frontend--flutter)
4. [Giao tiếp Flutter ↔ FastAPI ↔ Supabase](#4-giao-tiếp-flutter--fastapi--supabase)
5. [Database — Supabase PostgreSQL](#5-database--supabase-postgresql)
6. [Xác thực & Bảo mật](#6-xác-thực--bảo-mật)
7. [Xử lý lỗi & States](#7-xử-lý-lỗi--states)
8. [Luồng dữ liệu](#8-luồng-dữ-liệu)

---

## 1. Tổng quan kiến trúc

```
┌────────────────────────────────────────────────────────────┐
│                    FLUTTER APP                              │
│  Screen ← Provider ← Service (HTTP) ←→ FastAPI            │
│  Auth: supabase_flutter SDK (đăng nhập trực tiếp)         │
└──────────────────────────┬─────────────────────────────────┘
                           │ REST API + Bearer JWT
┌──────────────────────────┴─────────────────────────────────┐
│                    FASTAPI BACKEND                          │
│  Routers → Services → SQLAlchemy ORM → Supabase PostgreSQL │
│  Auth: verify JWT từ Supabase bằng PyJWT                   │
│  Deploy: Render Web Service                                │
└──────────────────────────┬─────────────────────────────────┘
                           │
┌──────────────────────────┴─────────────────────────────────┐
│                    SUPABASE CLOUD                           │
│  ┌──────────────────────┐  ┌──────────────────────────┐   │
│  │  PostgreSQL Database  │  │  Supabase Auth           │   │
│  │  + Row Level Security │  │  + JWT tokens            │   │
│  └──────────────────────┘  └──────────────────────────┘   │
└────────────────────────────────────────────────────────────┘
```

### Cách Supabase hoạt động

| Thành phần | Cách dùng | Vai trò |
|-----------|-----------|---------|
| **Supabase Auth** | Flutter: `supabase_flutter` đăng nhập | Cấp JWT token |
| **Supabase PostgreSQL** | FastAPI kết nối qua SQLAlchemy async | Lưu dữ liệu |
| **JWT verify** | FastAPI verify token bằng PyJWT | Bảo mật API |

---

## 2. Backend — FastAPI

### 2.1 Cấu trúc thư mục (bắt buộc)

```
backend/
├── main.py                       # Entry point, include routers, CORS
├── database.py                   # SQLAlchemy engine async (Supabase PostgreSQL)
├── models.py                     # SQLAlchemy models (User, Vocabulary, QuizResult, QuizCategory)
├── schemas.py                    # Pydantic request/response
├── services/                     # Business logic layer
│   ├── __init__.py
│   ├── auth_service.py           # Verify JWT Supabase, đồng bộ user
│   ├── vocabulary_service.py     # CRUD + search + filter
│   ├── quiz_service.py           # Sinh câu hỏi, chấm điểm
│   └── dashboard_service.py      # Thống kê
├── routers/                      # API endpoints
│   ├── __init__.py
│   ├── auth.py
│   ├── vocabulary.py
│   ├── quiz.py
│   └── dashboard.py
├── core/
│   ├── __init__.py
│   ├── config.py                 # Settings từ env
│   └── security.py              # get_current_user dependency
├── requirements.txt
└── venv/
```

### 2.2 Quy tắt code Backend

| # | Rule |
|---|------|
| R1 | Mỗi router 1 resource, prefix `/api/resource` |
| R2 | Endpoint cần auth → `current_user = Depends(get_current_user)` |
| R3 | Luôn khai báo `response_model=` trên router decorator |
| R4 | Pydantic response schema: `from_attributes = True` |
| R5 | Router **không chứa logic** — chỉ gọi service → trả response |
| R6 | Service **chứa toàn bộ business logic** (sinh câu hỏi, tính điểm, search) |
| R7 | Lỗi → `HTTPException` với status code chuẩn |

### 2.3 Service Layer Pattern

```python
# Router: chỉ gọi service
@router.get("/")
async def list_vocab(
    service: VocabularyService = Depends(get_vocab_service),
    current_user: models.User = Depends(get_current_user),
):
    items, total = await service.get_list(user_id=current_user.id, ...)
    return {"items": items, "total": total}

# Service: chứa logic
class VocabularyService:
    async def get_list(self, user_id, page, limit, search, topic):
        # query SQLAlchemy
        # filter
        # phân trang
        # return
```

### 2.4 Router Naming Convention

| File | Prefix | Tags |
|------|--------|------|
| `routers/auth.py` | `/api/auth` | `["Auth"]` |
| `routers/vocabulary.py` | `/api/vocabularies` | `["Vocabulary"]` |
| `routers/quiz.py` | `/api/quiz` | `["Quiz"]` |
| `routers/dashboard.py` | `/api/dashboard` | `["Dashboard"]` |
| `routers/gamification.py` | `/api/gamification` | `["Gamification"]` |
| `routers/mock_test.py` | `/api/mock-tests` | `["Mock Tests"]` |

---

## 3. Frontend — Flutter

### 3.1 Cấu trúc thư mục (bắt buộc)

```
frontend/lib/
├── main.dart                       # runApp + init Supabase
├── app.dart                        # MaterialApp.router + Theme + GoRouter
├── config/
│   └── api_config.dart             # FastAPI base URL
├── models/                         # Data classes (fromMap + toMap)
│   ├── user.dart
│   ├── vocabulary.dart
│   ├── quiz_result.dart
│   └── quiz_category.dart
├── services/                       # HTTP services (gọi FastAPI)
│   ├── api_service.dart            # HTTP client base + JWT interceptor
│   ├── vocabulary_service.dart
│   ├── quiz_service.dart
│   └── dashboard_service.dart
├── providers/                      # State (ChangeNotifier)
│   ├── auth_provider.dart
│   ├── vocabulary_provider.dart
│   ├── quiz_provider.dart
│   └── dashboard_provider.dart
├── screens/                        # Pages
│   ├── splash_screen.dart
│   ├── onboarding_screen.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── dashboard_screen.dart
│   ├── vocabulary_list_screen.dart
│   ├── vocabulary_form_screen.dart
│   ├── quiz_list_screen.dart
│   ├── quiz_play_screen.dart
│   ├── quiz_result_screen.dart
│   ├── quiz_history_screen.dart
│   ├── mock_test_screen.dart
│   ├── mock_test_play_screen.dart
│   ├── mock_test_result_screen.dart
│   └── profile_screen.dart
└── widgets/                        # Widget dùng chung
    ├── streak_bar.dart
    ├── review_card.dart
    ├── skill_grid.dart
    ├── stats_grid.dart
    ├── progress_bar_skill.dart
    ├── flashcard_widget.dart
    ├── vocab_card.dart
    ├── question_card.dart
    ├── leaderboard_preview.dart
    ├── mock_test_card.dart
    ├── loading_widget.dart
    ├── empty_state_widget.dart
    ├── error_state_widget.dart
    ├── cat_widget.dart
    └── app_drawer.dart
│   └── quiz_history_screen.dart
└── widgets/                        # Widget dùng chung
    ├── app_drawer.dart
    ├── stats_card.dart
    ├── vocab_card.dart
    ├── question_card.dart
    ├── loading_widget.dart
    ├── empty_state_widget.dart
    └── error_state_widget.dart
```

### 3.2 Quy tắt code Flutter

| # | Rule |
|---|------|
| F1 | Model: `factory fromJson` + `toJson`, tất cả field `final` |
| F2 | Provider: `extends ChangeNotifier`, 3 state (`isLoading`, `data`, `errorMessage`) |
| F3 | Mỗi Screen: 4 states (Loading → Error → Empty → Data) |
| F4 | Widget chung: `const constructor` + `super.key` |
| F5 | Dùng `Consumer<T>` / `context.watch<T>()` |
| F6 | Navigation: `context.go()` / `context.push()` (go_router) |
| F7 | Screen không gọi API trực tiếp — qua Provider → Service |
| F8 | Theme tập trung trong `app.dart` |

### 3.3 Auth Flow (Supabase Auth + FastAPI)

```
1. Flutter: supabase.auth.signIn(email, pass)  →  Supabase trả JWT
2. Flutter lưu token (supabase_flutter tự lưu)
3. Flutter gọi FastAPI: Authorization: Bearer <token>
4. FastAPI verify JWT bằng PyJWT + Supabase secret
5. FastAPI trả response
```

---

## 4. Giao tiếp Flutter ↔ FastAPI ↔ Supabase

### 4.1 ApiService (Flutter)

```dart
class ApiService {
  final String baseUrl;
  final http.Client _client = http.Client();

  Future<Map<String, String>> get _headers async {
    final session = Supabase.instance.client.auth.currentSession;
    return {
      'Content-Type': 'application/json',
      if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
    };
  }

  Future<dynamic> get(String path, {Map<String, String>? params}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: params);
    final response = await _client.get(uri, headers: await _headers);
    return _handleResponse(response);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client.post(uri, headers: await _headers, body: jsonEncode(body));
    return _handleResponse(response);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client.put(uri, headers: await _headers, body: jsonEncode(body));
    return _handleResponse(response);
  }

  Future<dynamic> delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client.delete(uri, headers: await _headers);
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    if (response.statusCode == 401) throw AuthException('Phiên đăng nhập hết hạn');
    final detail = jsonDecode(response.body)['detail'] ?? 'Lỗi không xác định';
    throw ApiException(response.statusCode, detail.toString());
  }
}
```

### 4.2 Backend Verify JWT (FastAPI)

```python
# core/security.py
from jose import JWTError, jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

security = HTTPBearer()

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_db),
) -> models.User:
    token = credentials.credentials
    try:
        payload = jwt.decode(
            token,
            settings.SUPABASE_JWT_SECRET,
            algorithms=["HS256"],
            audience="authenticated",
        )
        user_id = payload.get("sub")
        email = payload.get("email", "")
    except JWTError:
        raise HTTPException(status_code=401, detail="Token không hợp lệ")

    user = await auth_service.get_or_create_user(db, user_id, email)
    return user
```

---

## 5. Database — Supabase PostgreSQL

### 5.1 Cấu trúc bảng

```sql
-- users (đồng bộ từ Supabase Auth)
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  username TEXT,
  is_premium BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- vocabularies
CREATE TABLE vocabularies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  word TEXT NOT NULL,
  meaning TEXT NOT NULL,
  example TEXT,
  topic TEXT DEFAULT 'general',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_vocab_user_id ON vocabularies(user_id);
CREATE INDEX idx_vocab_topic ON vocabularies(user_id, topic);

-- quiz_results
CREATE TABLE quiz_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  quiz_type TEXT NOT NULL,
  total_questions INTEGER NOT NULL,
  correct_answers INTEGER NOT NULL,
  score_percent DECIMAL(5,2) NOT NULL,
  answers JSONB NOT NULL DEFAULT '[]',
  completed_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_quiz_user_id ON quiz_results(user_id);

-- quiz_categories (seed data)
CREATE TABLE quiz_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  icon TEXT
);
INSERT INTO quiz_categories (title, description, icon) VALUES
  ('Chọn đáp án đúng', 'Xem từ, chọn nghĩa đúng', 'quiz'),
  ('Điền từ', 'Xem nghĩa, gõ từ phù hợp', 'edit'),
  ('Nghĩa của từ', 'Xem câu ví dụ, chọn nghĩa', 'translate');
```

### 5.2 SQLAlchemy Models

```python
from sqlalchemy import Column, String, Integer, Boolean, DateTime, ForeignKey, DECIMAL, Text, JSON
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
import uuid

class User(Base):
    __tablename__ = "users"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String(100), unique=True, nullable=False)
    username = Column(String(50))
    is_premium = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class Vocabulary(Base):
    __tablename__ = "vocabularies"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    word = Column(String(100), nullable=False)
    meaning = Column(String(200), nullable=False)
    example = Column(Text)
    topic = Column(String(50), default="general")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

class QuizResult(Base):
    __tablename__ = "quiz_results"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    quiz_type = Column(String(50), nullable=False)
    total_questions = Column(Integer, nullable=False)
    correct_answers = Column(Integer, nullable=False)
    score_percent = Column(DECIMAL(5,2), nullable=False)
    answers = Column(JSON, default=[])
    completed_at = Column(DateTime(timezone=True), server_default=func.now())

class QuizCategory(Base):
    __tablename__ = "quiz_categories"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    title = Column(String(100), nullable=False)
    description = Column(String(255))
    icon = Column(String(50))
```

---

## 6. Xác thực & Bảo mật

| Rule | Giá trị |
|------|---------|
| **Auth provider** | Supabase Auth (email/password) |
| **Flutter login** | `supabase_flutter` SDK |
| **Backend verify** | PyJWT + `SUPABASE_JWT_SECRET` |
| **Token gửi lên** | Header `Authorization: Bearer <token>` |
| **CORS (prod)** | Chỉ cho phép domain frontend |

---

## 7. Xử lý lỗi & States

### 7.1 Error messages (Tiếng Việt)

| Tình huống | Message |
|-----------|---------|
| Mất mạng | 'Không có kết nối Internet' |
| Server lỗi | 'Máy chủ đang bận. Vui lòng thử lại sau.' |
| Sai mật khẩu | 'Email hoặc mật khẩu không đúng.' |
| Token hết hạn | 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.' |

### 7.2 UI States Pattern

```dart
Consumer<T>(
  builder: (context, provider, _) {
    if (provider.isLoading) return const LoadingWidget();
    if (provider.hasError) return ErrorStateWidget(
      message: provider.errorMessage!,
      onRetry: () => provider.refresh(),
    );
    if (provider.items.isEmpty) return const EmptyStateWidget(
      icon: Icons.menu_book,
      title: 'Chưa có dữ liệu',
      action: 'Bắt đầu ngay',
    );
    return _buildContent(provider);
  },
)
```

---

## 8. Luồng dữ liệu

### 📊 Luồng chuẩn

```
Screen → Provider → Service (HTTP) → FastAPI → Supabase PostgreSQL
                     ↑
            Supabase Auth (JWT token)
```

### 📊 Luồng Realtime (Vocabulary List)

```
1. User vào VocabularyListScreen
2. Provider.fetchAll(userId)  →  Service.getList()
3. Service gọi GET /api/vocabularies với Bearer JWT
4. FastAPI: verify JWT → VocabularyService.get_list() → SQL query
5. Supabase PostgreSQL trả rows
6. FastAPI serialize → JSON → Flutter
7. Provider cập nhật state → UI rebuild
```

---

## 9. Checklist trước commit

- [ ] `flutter analyze` không lỗi
- [ ] Backend API test qua Swagger docs
- [ ] Model có `fromJson` / `toMap` và `toJson` / `fromMap`
- [ ] Provider đúng 3-state pattern
- [ ] Screen xử lý đủ Loading / Error / Empty / Data
- [ ] Widget chung có `const constructor` + `super.key`
- [ ] Error message tiếng Việt thân thiện
- [ ] Không còn `print()` rác
