from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from core.config import settings
from database import init_db, close_db, async_session_factory
from routers import auth, vocabulary, quiz, dashboard, gamification, mock_test, ai


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Handle application startup and shutdown events."""
    # Startup: create tables (local dev) or ensure they exist
    await init_db()
    yield
    # Shutdown: dispose database engine
    await close_db()


app = FastAPI(
    title="Ứng dụng Học Từ Vựng API",
    description="FastAPI backend cho ứng dụng học từ vựng tích hợp Supabase",
    version="1.1.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
    redirect_slashes=False,
)

# CORS — use FRONTEND_URL in production, * for dev
origins = ["*"]
if settings.FRONTEND_URL and "localhost" not in settings.FRONTEND_URL:
    origins = [settings.FRONTEND_URL]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include all routers
app.include_router(auth.router)
app.include_router(vocabulary.router)
app.include_router(quiz.router)
app.include_router(dashboard.router)
app.include_router(gamification.router)
app.include_router(mock_test.router)
app.include_router(ai.router)


@app.get("/")
async def root():
    """Root endpoint — health check."""
    return {
        "message": "Ứng dụng Học Từ Vựng API",
        "version": "1.1.0",
        "docs": "/docs",
    }


@app.get("/health")
async def health_check():
    """Health check endpoint with DB connectivity verification."""
    db_ok = False
    try:
        async with async_session_factory() as session:
            await session.execute(text("SELECT 1"))
            db_ok = True
    except Exception:
        db_ok = False
    return {"status": "ok" if db_ok else "degraded", "database": "connected" if db_ok else "disconnected"}
