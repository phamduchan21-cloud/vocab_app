# 🎯 Quy tắc dự án — Ứng dụng Học Từ Vựng

> **Stack:** Flutter 3.44 (Dart) · FastAPI (Python) · Supabase (PostgreSQL + Auth)  
> **Kiến trúc chi tiết:** Xem [ARCHITECTURE.md](ARCHITECTURE.md)  
> **Plan tổng thể:** Xem [PLAN.md](PLAN.md)

---

## 📋 Quy tắc chung

### 1. Convention đặt tên

| Ngôn ngữ | Files | Classes | Biến / Hàm |
|----------|-------|---------|-----------|
| **Python** | `snake_case.py` | `PascalCase` (class) · `snake_case` (func) | `snake_case` |
| **Dart** | `snake_case.dart` | `PascalCase` (class/widget) | `camelCase` |
| **JSON API** | — | — | `snake_case` (FastAPI mặc định) |

### 2. Thứ tự code

```
Backend: imports → constants → models/schemas → services → routers
Flutter: imports → constants → model → service → provider → screen
```

### 3. UI Language
- **Tiếng Việt** cho text người dùng thấy
- **Tiếng Anh** cho code (biến, hàm, class, comment)

---

## ⚙️ Backend (FastAPI + Supabase)

### Thư viện bắt buộc

```
fastapi, uvicorn, sqlalchemy[asyncio], asyncpg, psycopg2-binary, pydantic, python-jose, supabase, httpx
```

### Cấu trúc bắt buộc

```
backend/
├── main.py          # app + include_routers + CORS
├── database.py      # engine async + get_db
├── models.py        # SQLAlchemy (User, Vocabulary, QuizResult, QuizCategory)
├── schemas.py       # Pydantic
├── services/        # Business logic (auth, vocabulary, quiz, dashboard)
├── routers/         # API endpoints
└── core/            # config.py, security.py
```

### Rules

| # | Rule |
|---|------|
| R1 | Router prefix: `/api/resource`, tags: `["Resource"]` |
| R2 | Endpoint auth: `current_user = Depends(get_current_user)` |
| R3 | Luôn có `response_model=` trên router decorator |
| R4 | Pydantic response: `from_attributes = True` |
| R5 | **Router KHÔNG chứa logic** → chỉ gọi service |
| R6 | Service chứa business logic (sinh câu hỏi, tính điểm, search) |
| R7 | Database: Supabase PostgreSQL qua SQLAlchemy async |

---

## 📱 Frontend (Flutter + Supabase)

### Thư viện bắt buộc

```yaml
dependencies:
  flutter: sdk
  supabase_flutter: ^2.x
  http: ^1.2.0
  provider: ^6.1.0
  go_router: ^14.0.0
```

### Cấu trúc bắt buộc

```
frontend/lib/
├── main.dart               # runApp + Supabase.initialize()
├── app.dart                # MaterialApp.router + GoRouter + Theme
├── config/api_config.dart  # FastAPI base URL
├── models/                 # fromJson + toJson (tất cả field final)
├── services/               # HTTP services (gọi FastAPI)
├── providers/              # ChangeNotifier (3 state)
├── screens/                # Mỗi màn hình 1 file
└── widgets/                # Widget dùng chung
```

### Rules

| # | Rule |
|---|------|
| F1 | Model: `factory fromJson` + `toJson`, tất cả field `final` |
| F2 | Provider: `extends ChangeNotifier`, 3 state vars (`_isLoading`, `_data`, `_errorMessage`) |
| F3 | Screen: 4 states (Loading → Error → Empty → Data) |
| F4 | Widget chung: `const constructor` + `super.key` |
| F5 | Navigation: `context.go()` (go_router) |
| F6 | Screen → Provider → Service → API (không gọi API trực tiếp từ Screen) |
| F7 | Theme tập trung trong `app.dart`, không hardcode màu |
| F8 | Auth: dùng `supabase_flutter`, token tự gắn vào header ApiService |

---

## 🔄 Quy trình code

### Mỗi tính năng mới

```
1. Backend: Model → Schema → Service → Router
2. Frontend: Model → Service → Provider → Screen
3. Test backend: Swagger docs (localhost:8000/docs)
4. Test frontend: flutter run -d chrome
```

### Gặp lỗi → debug

```
1. Đọc lỗi backend (console + Swagger)
2. Kiểm tra Flutter logs
3. Sửa backend nếu là lỗi API
4. Sửa frontend sau
```

---

## ✅ Checklist trước commit

- [ ] `flutter analyze` 0 lỗi
- [ ] Backend chạy được `uvicorn main:app` — Swagger docs hoạt động
- [ ] Model có `fromJson` + `toJson` (Flutter) / đúng SQLAlchemy (Python)
- [ ] Provider đúng 3-state pattern
- [ ] Screen xử lý đủ Loading / Error / Empty / Data
- [ ] Widget chung có `const constructor`
- [ ] Error message tiếng Việt, thân thiện
- [ ] Không còn `print()` / `console.log()` rác
- [ ] Đúng convention tên file (snake_case)
