from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from core.config import settings
from database import init_db, close_db
from routers import auth, vocabulary, quiz, dashboard, gamification, mock_test


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
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
    redirect_slashes=False,
)

# CORS middleware — allow all origins for development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
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


@app.get("/")
async def root():
    """Root endpoint — health check."""
    return {
        "message": "Ứng dụng Học Từ Vựng API",
        "version": "1.0.0",
        "docs": "/docs",
    }


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "ok"}
