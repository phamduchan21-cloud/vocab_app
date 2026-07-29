"""Add rewards wallet and CEFR learning path.

Revision ID: f2a3b4c5d6e7
Revises: e1f2a3b4c5d6
Create Date: 2026-07-29
"""

from typing import Sequence, Union

from alembic import op


revision: str = "f2a3b4c5d6e7"
down_revision: Union[str, Sequence[str], None] = "e1f2a3b4c5d6"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(
        """
        CREATE TABLE IF NOT EXISTS user_wallets (
            user_id VARCHAR(36) PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
            gems_balance INTEGER NOT NULL DEFAULT 0,
            updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        )
        """
    )
    op.execute(
        """
        CREATE TABLE IF NOT EXISTS user_rewards (
            id VARCHAR(36) PRIMARY KEY,
            user_id VARCHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            reward_key VARCHAR(80) NOT NULL,
            source_type VARCHAR(30) NOT NULL DEFAULT 'achievement',
            title VARCHAR(120) NOT NULL,
            description VARCHAR(255),
            xp_amount INTEGER NOT NULL DEFAULT 0,
            gems_amount INTEGER NOT NULL DEFAULT 0,
            status VARCHAR(20) NOT NULL DEFAULT 'pending',
            unlocked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            claimed_at TIMESTAMPTZ,
            CONSTRAINT uq_user_reward_key UNIQUE (user_id, reward_key)
        )
        """
    )
    op.execute(
        """
        CREATE TABLE IF NOT EXISTS reward_transactions (
            id VARCHAR(36) PRIMARY KEY,
            user_id VARCHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            transaction_key VARCHAR(100) NOT NULL,
            source_type VARCHAR(30) NOT NULL,
            source_id VARCHAR(36),
            xp_delta INTEGER NOT NULL DEFAULT 0,
            gems_delta INTEGER NOT NULL DEFAULT 0,
            description VARCHAR(255),
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            CONSTRAINT uq_reward_transaction_key UNIQUE (user_id, transaction_key)
        )
        """
    )
    op.execute(
        """
        CREATE TABLE IF NOT EXISTS user_learning_paths (
            user_id VARCHAR(36) PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
            current_cefr VARCHAR(2) NOT NULL DEFAULT 'A1',
            current_step INTEGER NOT NULL DEFAULT 0,
            placement_source VARCHAR(20) NOT NULL DEFAULT 'profile',
            started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        )
        """
    )
    op.execute(
        """
        CREATE TABLE IF NOT EXISTS user_path_steps (
            id VARCHAR(36) PRIMARY KEY,
            user_id VARCHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            cefr_level VARCHAR(2) NOT NULL,
            status VARCHAR(20) NOT NULL DEFAULT 'locked',
            progress_percent DOUBLE PRECISION NOT NULL DEFAULT 0,
            quiz_average DOUBLE PRECISION NOT NULL DEFAULT 0,
            mini_test_score DOUBLE PRECISION NOT NULL DEFAULT 0,
            completed_at TIMESTAMPTZ,
            updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            CONSTRAINT uq_user_path_step UNIQUE (user_id, cefr_level)
        )
        """
    )
    op.execute(
        """
        CREATE INDEX IF NOT EXISTS idx_user_reward_status
        ON user_rewards (user_id, status)
        """
    )
    op.execute(
        """
        CREATE INDEX IF NOT EXISTS idx_reward_transaction_user
        ON reward_transactions (user_id, created_at)
        """
    )
    op.execute(
        """
        CREATE INDEX IF NOT EXISTS idx_user_path_step_status
        ON user_path_steps (user_id, status)
        """
    )

    # Preserve the previous visible gems balance and prevent historical claims.
    op.execute(
        """
        INSERT INTO user_wallets (user_id, gems_balance)
        SELECT u.id, COALESCE(SUM(a.xp_earned), 0) / 10
        FROM users u
        LEFT JOIN user_daily_activities a ON a.user_id = u.id
        GROUP BY u.id
        ON CONFLICT (user_id) DO NOTHING
        """
    )
    op.execute(
        """
        INSERT INTO user_rewards (
            id, user_id, reward_key, source_type, title, description,
            xp_amount, gems_amount, status, unlocked_at, claimed_at
        )
        SELECT
            a.id, a.user_id, a.achievement_key, 'achievement', a.title,
            a.description, 0, 0, 'claimed', a.unlocked_at, a.unlocked_at
        FROM user_achievements a
        ON CONFLICT (user_id, reward_key) DO NOTHING
        """
    )


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS user_path_steps")
    op.execute("DROP TABLE IF EXISTS user_learning_paths")
    op.execute("DROP TABLE IF EXISTS reward_transactions")
    op.execute("DROP TABLE IF EXISTS user_rewards")
    op.execute("DROP TABLE IF EXISTS user_wallets")
