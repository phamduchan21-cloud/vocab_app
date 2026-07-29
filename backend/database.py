from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import DeclarativeBase
from sqlalchemy import text
from typing import AsyncGenerator

from core.config import settings


# SSL connect args cho Supabase PostgreSQL
_connect_args = {}
if settings.DATABASE_URL and "sqlite" not in settings.DATABASE_URL:
    _connect_args = {"ssl": "require"}


# Create async engine
_pool_kwargs = {}
if "sqlite" not in settings.DATABASE_URL:
    _pool_kwargs = dict(
        pool_size=5,
        max_overflow=5,
        pool_timeout=30,
        pool_pre_ping=True,
    )

engine = create_async_engine(
    settings.DATABASE_URL,
    echo=False,
    future=True,
    connect_args=_connect_args,
    **_pool_kwargs,
)

# Create async session factory
async_session_factory = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


class Base(DeclarativeBase):
    pass


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """FastAPI dependency that yields an async database session."""
    async with async_session_factory() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


async def init_db():
    """Create missing tables and apply safe runtime backfills."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        if "sqlite" in settings.DATABASE_URL:
            if not await _sqlite_has_column(conn, "vocabularies", "is_bookmarked"):
                await conn.execute(
                    text(
                        "ALTER TABLE vocabularies "
                        "ADD COLUMN is_bookmarked BOOLEAN DEFAULT 0"
                    )
                )
            if not await _sqlite_has_column(conn, "vocabularies", "review_interval"):
                await conn.execute(
                    text(
                        "ALTER TABLE vocabularies "
                        "ADD COLUMN review_interval INTEGER DEFAULT 0"
                    )
                )
            if not await _sqlite_has_column(conn, "vocabularies", "personal_note"):
                await conn.execute(
                    text("ALTER TABLE vocabularies ADD COLUMN personal_note TEXT")
                )
            return

        # Existing users keep the gem balance shown before wallets were persisted.
        await conn.execute(
            text(
                """
                INSERT INTO user_wallets (user_id, gems_balance)
                SELECT users.id, COALESCE(SUM(user_daily_activities.xp_earned), 0) / 10
                FROM users
                LEFT JOIN user_daily_activities
                    ON user_daily_activities.user_id = users.id
                GROUP BY users.id
                ON CONFLICT (user_id) DO NOTHING
                """
            )
        )
        # Historical achievements are marked claimed to prevent duplicate payouts.
        await conn.execute(
            text(
                """
                INSERT INTO user_rewards (
                    id, user_id, reward_key, source_type, title, description,
                    xp_amount, gems_amount, status, unlocked_at, claimed_at
                )
                SELECT
                    user_achievements.id,
                    user_achievements.user_id,
                    user_achievements.achievement_key,
                    'achievement',
                    user_achievements.title,
                    user_achievements.description,
                    0,
                    0,
                    'claimed',
                    user_achievements.unlocked_at,
                    user_achievements.unlocked_at
                FROM user_achievements
                ON CONFLICT (user_id, reward_key) DO NOTHING
                """
            )
        )


async def _sqlite_has_column(conn, table: str, column: str) -> bool:
    """Check lightweight local-dev schema upgrades missed by create_all."""
    result = await conn.execute(text(f"PRAGMA table_info({table})"))
    return any(row[1] == column for row in result.fetchall())


async def close_db():
    """Dispose the engine."""
    await engine.dispose()
