# 🛡️ QUY TẮC & LUẬT LỆ DỰ ÁN — MeuBeu

> **File này quy định bắt buộc trước khi code.** Đọc kỹ trước khi thực hiện bất kỳ thay đổi nào.

---

## 1. 📖 NGUYÊN TẮC BẮT BUỘC

### 1.1 Trước khi code — PHẢI đọc các file sau

| File | Nội dung | Bắt buộc |
|------|----------|:--------:|
| `CLAUDE.md` | Rules chung dự án (convention đặt tên, thứ tự code) | ✅ **Luôn đọc** |
| `PLAN.md` | Kế hoạch tổng thể, feature list, API design | ✅ **Luôn đọc** |
| `ARCHITECTURE.md` | Kiến trúc backend/frontend | ✅ **Luôn đọc** |
| `SKILL.md` | File này — luật lệ code | ✅ **Luôn đọc** |

### 1.2 Checklist trước commit

- [ ] `flutter analyze` 0 lỗi
- [ ] Backend chạy được `uvicorn main:app` — Swagger docs hoạt động
- [ ] Model có `fromJson` + `toJson` (Flutter) / đúng SQLAlchemy (Python)
- [ ] Provider đúng 3-state pattern (isLoading, data, errorMessage)
- [ ] Screen xử lý đủ Loading / Error / Empty / Data
- [ ] Widget chung có `const constructor`
- [ ] Error message tiếng Việt, thân thiện
- [ ] Không còn `print()` / `console.log()` rác
- [ ] Đúng convention tên file (snake_case)

---

## 2. 📂 CẤU TRÚC THƯ MỤC

### 2.1 Backend (`backend/`)

```
backend/
├── main.py              # App FastAPI + include_routers + CORS
├── database.py          # Engine async + get_db
├── models.py            # SQLAlchemy (tất cả models)
├── schemas.py           # Pydantic (tất cả schemas)
├── services/            # Business logic
│   ├── auth_service.py
│   ├── vocabulary_service.py
│   ├── quiz_service.py
│   ├── listening_service.py
│   ├── reading_service.py
│   ├── speaking_service.py
│   ├── mock_test_service.py
│   ├── dashboard_service.py
│   └── gamification_service.py
├── routers/             # API endpoints
│   ├── auth.py
│   ├── vocabulary.py
│   ├── quiz.py
│   ├── listening.py
│   ├── reading.py
│   ├── speaking.py
│   ├── mock_test.py
│   ├── dashboard.py
│   └── gamification.py
└── core/
    ├── config.py        # Settings từ env
    └── security.py      # get_current_user
```

### 2.2 Frontend (`frontend/`)

```
frontend/lib/
├── main.dart            # runApp + Supabase.initialize()
├── app.dart             # GoRouter + Theme
├── config/api_config.dart
├── models/              # final field, fromJson, toJson
├── services/            # HTTP services (gọi FastAPI)
├── providers/           # ChangeNotifier — 3 state pattern
├── screens/             # Mỗi màn hình 1 file
└── widgets/             # const constructor, super.key
```

---

## 3. 📐 CONVENTION ĐẶT TÊN

| Ngôn ngữ | Files | Classes | Biến / Hàm |
|----------|-------|---------|-----------|
| **Python** | `snake_case.py` | `PascalCase` (class) · `snake_case` (func) | `snake_case` |
| **Dart** | `snake_case.dart` | `PascalCase` (class/widget) | `camelCase` |
| **JSON API** | — | — | `snake_case` (FastAPI mặc định) |

---

## 4. ⚙️ BACKEND RULES

| # | Rule | Mô tả |
|:-:|------|-------|
| R1 | **Router prefix** | `/api/resource`, tags: `["Resource"]` |
| R2 | **Endpoint auth** | `current_user = Depends(get_current_user)` |
| R3 | **response_model** | Luôn có `response_model=` trên router decorator |
| R4 | **Pydantic** | Response: `from_attributes = True` |
| R5 | **Router NO logic** | Router chỉ gọi service, không chứa logic |
| R6 | **Service** | Chứa business logic (sinh câu hỏi, tính điểm) |
| R7 | **Database** | Supabase PostgreSQL qua SQLAlchemy async |
| R8 | **DB thật (Supabase)** | Code chạy với Supabase. Khi dev local dùng SQLite |

### 4.1 Thứ tự code backend

```
Model → Schema → Service → Router
```

### 4.2 Database — DÙNG SUPABASE

- Tất cả migration qua SQL script chạy trên Supabase SQL Editor
- `backend/database.py` kết nối Supabase PostgreSQL qua `asyncpg`
- Khi dev local dùng SQLite (`sqlite+aiosqlite:///./app.db`)
- Khi deploy dùng: `postgresql+asyncpg://postgres:...@db.xxx.supabase.co:5432/postgres`
- **LUÔN** backup script SQL trong `PLAN.md`

---

## 5. 📱 FRONTEND RULES

| # | Rule | Mô tả |
|:-:|------|-------|
| F1 | **Model** | `factory fromJson` + `toJson`, tất cả field `final` |
| F2 | **Provider** | `extends ChangeNotifier`, 3 state vars: `_isLoading`, `_data`, `_errorMessage` |
| F3 | **Screen** | 4 states: Loading → Error → Empty → Data |
| F4 | **Widget chung** | `const constructor` + `super.key` |
| F5 | **Navigation** | `context.go()` (go_router) |
| F6 | **Architecture** | Screen → Provider → Service → API (không gọi API trực tiếp từ Screen) |
| F7 | **Theme** | Tập trung trong `app.dart`, không hardcode màu |
| F8 | **Auth** | Dùng `supabase_flutter`, token tự gắn vào header ApiService |

### 5.1 3-State Provider Pattern

```dart
class ExampleProvider extends ChangeNotifier {
  final ExampleService _service;

  bool _isLoading = false;
  ExampleData? _data;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  ExampleData? get data => _data;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _data = await _service.fetch();
    } catch (e) {
      _errorMessage = 'Rất tiếc! Không thể tải dữ liệu.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

### 5.2 Screen 4-State Pattern

```dart
Widget build(BuildContext context) {
  if (provider.isLoading && provider.data == null) return _buildLoading();
  if (provider.errorMessage != null && provider.data == null) return _buildError();
  if (provider.data == null || _isEmpty(provider.data!)) return _buildEmpty();
  return _buildContent();
}
```

---

## 6. 🗄️ DATABASE — SUPABASE

### 6.1 Kết nối

| Môi trường | URL | Ghi chú |
|:----------:|-----|---------|
| **Local** | `sqlite+aiosqlite:///./app.db` | File SQLite |
| **Production** | `postgresql+asyncpg://postgres:@db.xxx.supabase.co:5432/postgres` | Supabase Cloud |

### 6.2 Supabase Auth

- Flutter đăng nhập qua `supabase_flutter` SDK
- Supabase Auth trả về JWT token
- FastAPI verify token qua PyJWT với `SUPABASE_JWT_SECRET`
- Flutter gắn token vào header `Authorization: Bearer <token>`

### 6.3 Cấu trúc bảng

```sql
CREATE TABLE users (id UUID, email TEXT, username TEXT, is_premium BOOLEAN, created_at TIMESTAMPTZ);
CREATE TABLE vocabularies (id UUID, user_id UUID, word TEXT, meaning TEXT, example TEXT, topic TEXT, next_review_date DATE, ...);
CREATE TABLE quiz_results (id UUID, user_id UUID, quiz_type TEXT, skill_type TEXT, ...);
CREATE TABLE mock_tests (id UUID, user_id UUID, test_level TEXT, ...);
CREATE TABLE user_daily_activities (id UUID, user_id UUID, activity_date DATE, xp_earned INT, ...);
CREATE TABLE user_achievements (id UUID, user_id UUID, achievement_key TEXT, ...);
CREATE TABLE grammar_lessons (id UUID, part INT, title TEXT, theory TEXT, examples JSONB);
CREATE TABLE listening_questions (id UUID, question_type TEXT, level TEXT, ...);
CREATE TABLE reading_questions (id UUID, question_type TEXT, level TEXT, ...);
CREATE TABLE audio_files (id UUID, text_hash TEXT, audio_url TEXT);
```

---

## 7. 🎨 UI LANGUAGE

- **Tiếng Việt** cho text người dùng thấy
- **Tiếng Anh** cho code (biến, hàm, class, comment)

---

## 8. 🔄 QUY TRÌNH CODE MỖI TÍNH NĂNG

### 8.1 Trước khi code

```mermaid
graph LR
    A[Đọc PLAN.md] --> B[Đọc CLAUDE.md]
    B --> C[Đọc SKILL.md]
    C --> D[Lên plan]
    D --> E[Xác nhận với user]
    E --> F[Code]
```

### 8.2 Thứ tự code

```
Backend: Model → Schema → Service → Router
Frontend: Model → Service → Provider → Screen
Test backend: Swagger docs (localhost:8000/docs)
Test frontend: flutter run -d chrome
```

### 8.3 Gặp lỗi → debug

```
1. Đọc lỗi backend (console + Swagger)
2. Kiểm tra Flutter logs
3. Sửa backend nếu là lỗi API
4. Sửa frontend sau
```

---

## 9. 📊 DANH SÁCH TÍNH NĂNG & TRẠNG THÁI

### 9.1 Đã code (41 files)

| Module | Backend | Frontend |
|--------|:-------:|:--------:|
| Auth (Login/Register) | ✅ | ✅ |
| Dashboard | ✅ | ✅ |
| Vocabulary CRUD | ✅ | ✅ |
| Quiz (generate/submit) | ✅ | ✅ |
| Mock Test | ✅ | ✅ |
| Gamification (Streak, XP) | ✅ | ✅ |
| AI Speaking | ✅ | ✅ |
| Grammar Lessons | — | ✅ (UI mẫu) |

### 9.2 Cần code

| Tính năng | Backend | Frontend | Mức độ |
|-----------|:-------:|:--------:|:------:|
| Listening Screen (8 dạng bài) | ⏳ Đang làm | ⏳ | ⭐⭐⭐ |
| Reading Screen (7 dạng bài) | ❌ | ❌ | ⭐⭐⭐ |
| Vocabulary 15 bài + 3 Tab | ❌ | ❌ | ⭐⭐⭐ |
| Profile + 24 Achievements | ⏳ | ❌ | ⭐⭐ |
| Learning Path IELTS | ❌ | ❌ | ⭐⭐ |
| Writing AI | ❌ | ❌ | ⭐⭐⭐ |
| Video Learning | ❌ | ❌ | ⭐⭐ |
| AI Assistant | ❌ | ❌ | ⭐⭐ |

---

## 10. 🚀 DEPLOY

| Nền tảng | Cách deploy |
|----------|------------|
| **Backend** | Render — Web Service FastAPI |
| **Frontend Web** | Vercel — upload `build/web/` |
| **Android** | `flutter build apk` → file `.apk` |

### Biến môi trường

| Variable | Mô tả |
|----------|-------|
| `SUPABASE_URL` | Supabase Project URL |
| `SUPABASE_ANON_KEY` | Supabase Anon Key |
| `SUPABASE_JWT_SECRET` | JWT Secret |
| `DATABASE_URL` | Supabase PostgreSQL URL |
| `GEMINI_API_KEY` | API Key cho Gemini AI |
| `FRONTEND_URL` | URL frontend (CORS) |

---

> **Lưu ý cuối:** Mọi thay đổi phải được kiểm tra bằng `flutter analyze` (0 lỗi) và Swagger docs hoạt động trước khi commit.
> **Quy Ä‘á»‹nh encoding:** Táº¥t cáº£ file text, code vÃ  Markdown pháº£i lÆ°u báº±ng `UTF-8` Ä‘á»ƒ trÃ¡nh lá»—i font chá»¯ vÃ  vá»¡ tiáº¿ng Viá»‡t.
