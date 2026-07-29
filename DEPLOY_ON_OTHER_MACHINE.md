# Huong dan deploy VocabApp tren may khac

Cap nhat tu workspace hien tai: `D:\AppHocTuVung`

## 1. Thong tin source code

- GitHub repo: `https://github.com/phamduchan21-cloud/vocab_app.git`
- Branch: `main`
- Commit da push gan nhat: `b420e1798e720f65b68144d17288d25e29802744`

Clone tren may moi:

```powershell
git clone https://github.com/phamduchan21-cloud/vocab_app.git
cd vocab_app
```

## 2. Yeu cau cai dat

- Flutter: `3.44.4` hoac moi hon trong kenh stable
- Dart: `3.12.2` di kem Flutter hien tai
- Python: dang dung local `3.14.6`; backend cung chay duoc voi Python moi mien tuong thich cac package trong `backend/requirements.txt`
- Git
- Neu deploy frontend len Vercel: nen cai Vercel CLI bang `npm i -g vercel`

## 3. Backend FastAPI

Thu muc backend:

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

Tao file `backend/.env` tren may moi. Cac gia tri nhay cam copy truc tiep tu may hien tai tai:

```text
D:\AppHocTuVung\backend\.env
```

Mau `.env` can co:

```env
SUPABASE_URL=https://tblagqcnhciqtmyhikoh.supabase.co
SUPABASE_ANON_KEY=<copy tu backend/.env hoac frontend/lib/config/api_config.dart>
SUPABASE_JWT_SECRET=<copy tu backend/.env>

# Local dev co the dung SQLite
DATABASE_URL=sqlite+aiosqlite:///./app.db

# Khi deploy production nen dung Supabase PostgreSQL async URL
DATABASE_URL=postgresql+asyncpg://postgres:<PASSWORD>@db.tblagqcnhciqtmyhikoh.supabase.co:5432/postgres

FRONTEND_URL=http://localhost:3000

# Tuy chon, de bat tinh nang AI
GEMINI_API_KEY=<copy tu backend/.env neu can>
OPENAI_API_KEY=<copy tu backend/.env neu can>
```

Chay backend local:

```powershell
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Kiem tra:

```text
http://127.0.0.1:8000/
http://127.0.0.1:8000/health
http://127.0.0.1:8000/docs
```

## 4. Database Supabase

Project Supabase:

```text
https://tblagqcnhciqtmyhikoh.supabase.co
```

Neu tao database moi, chay file SQL nay trong Supabase SQL Editor:

```text
supabase_schema.sql
```

Neu dung lai project Supabase hien tai, chi can copy dung `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_JWT_SECRET`, va `DATABASE_URL`.

## 5. Frontend Flutter Web

Thu muc frontend:

```powershell
cd frontend
flutter pub get
```

Chay local:

```powershell
flutter run -d chrome --web-port 3000 --dart-define=API_BASE_URL=http://localhost:8000
```

Build web de deploy:

```powershell
flutter build web --release --dart-define=API_BASE_URL=https://<backend-domain-cua-ban>
```

Sau khi build, thu muc can deploy la:

```text
frontend/build/web
```

## 6. Cau hinh OAuth Google/Facebook

Callback ve Supabase:

```text
https://tblagqcnhciqtmyhikoh.supabase.co/auth/v1/callback
```

Redirect allow list trong Supabase Authentication:

```text
http://localhost:3000/**
http://127.0.0.1:3000/**
com.vocabapp.vocab_app://login-callback/**
https://<frontend-domain-cua-ban>/**
```

Khi deploy production, can them domain frontend moi vao:

- Supabase Dashboard > Authentication > URL Configuration
- Google OAuth Client > JavaScript origins va Authorized redirect URI
- Meta/Facebook Login > Valid OAuth Redirect URIs

Huong dan chi tiet: `docs/OAUTH_SETUP.md`

## 7. Deploy Render backend

Repo da co `render.yaml` va `backend/render.yaml`.

Render settings:

```text
Runtime: Python
Root directory: backend
Build command: pip install -r requirements.txt
Start command: uvicorn main:app --host 0.0.0.0 --port $PORT
```

Env vars can nhap tren Render:

```text
SUPABASE_URL
SUPABASE_ANON_KEY
SUPABASE_JWT_SECRET
DATABASE_URL
FRONTEND_URL
GEMINI_API_KEY
OPENAI_API_KEY
```

`FRONTEND_URL` phai la domain frontend production de CORS cho phep goi API.

## 8. Deploy Vercel frontend

Repo co `frontend/vercel.json`:

```json
{
  "outputDirectory": "build/web",
  "buildCommand": null,
  "devCommand": "flutter run -d chrome --web-port 3000",
  "installCommand": null,
  "cleanUrls": true
}
```

Cach chac chan nhat:

```powershell
cd frontend
flutter pub get
flutter build web --release --dart-define=API_BASE_URL=https://<backend-domain-cua-ban>
```

Sau do deploy thu muc `frontend/build/web` bang hosting ban chon. Neu dung Vercel CLI, cai truoc:

```powershell
npm i -g vercel
```

## 9. Checklist sau khi deploy

- Backend `/health` tra `status: ok` va `database: connected`
- Backend `/docs` mo duoc Swagger
- Frontend mo duoc trang login
- Dang ky email/password tao duoc user Supabase
- Sau dang nhap vao duoc Home, khong bi day ve Login
- Google/Facebook OAuth chi hoat dong sau khi provider duoc bat trong Supabase va da khai bao dung callback/origin
- Khi doi domain frontend/backend, build lai frontend voi `--dart-define=API_BASE_URL=...`
