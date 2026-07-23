from contextlib import asynccontextmanager

from fastapi import FastAPI, Response, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy import text

import schemas
from core.config import settings
from core.observability import RequestContextMiddleware, configure_logging
from database import init_db, close_db, async_session_factory
from routers import auth, vocabulary, quiz, dashboard, gamification, mock_test, ai
from services.auth_service import AuthServiceError


configure_logging(settings.LOG_LEVEL)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Handle application startup and shutdown events."""
    # Startup: create tables (local dev) or ensure they exist
    await init_db()
    yield
    # Shutdown: dispose database engine
    await close_db()


app = FastAPI(
    title="SolVocab API",
    description="API học từ vựng thích nghi cho SolVocab, tích hợp Supabase",
    version="1.1.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
    redirect_slashes=False,
)


@app.exception_handler(AuthServiceError)
async def auth_service_error_handler(_, exc: AuthServiceError):
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.message},
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
app.add_middleware(RequestContextMiddleware)

# Include all routers
app.include_router(auth.router)
app.include_router(vocabulary.router)
app.include_router(quiz.router)
app.include_router(dashboard.router)
app.include_router(gamification.router)
app.include_router(mock_test.router)
app.include_router(ai.router)


@app.get("/", response_model=schemas.RootResponse)
async def root():
    """Root endpoint — health check."""
    return {
        "message": "SolVocab API",
        "version": "1.1.0",
        "docs": "/docs",
    }


@app.get("/health", response_model=schemas.HealthResponse)
async def health_check(response: Response):
    """Health check endpoint with DB connectivity verification."""
    db_ok = False
    try:
        async with async_session_factory() as session:
            await session.execute(text("SELECT 1"))
            db_ok = True
    except Exception:
        db_ok = False
    if not db_ok:
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
    return {
        "status": "ok" if db_ok else "degraded",
        "database": "connected" if db_ok else "disconnected",
    }


@app.get("/health/live", response_model=schemas.LivenessResponse)
async def liveness_check():
    """Liveness check that does not depend on external services."""
    return {"status": "ok"}
