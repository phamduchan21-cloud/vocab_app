"""Repair columns missing from the production schema.

Revision ID: e1f2a3b4c5d6
Revises: d9a4e5f6b7c8
Create Date: 2026-07-29
"""

from typing import Sequence, Union

from alembic import op


revision: str = "e1f2a3b4c5d6"
down_revision: Union[str, Sequence[str], None] = "d9a4e5f6b7c8"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Keep this repair safe for databases partially updated via Supabase SQL.
    op.execute(
        """
        ALTER TABLE vocabularies
            ADD COLUMN IF NOT EXISTS review_interval INTEGER DEFAULT 0,
            ADD COLUMN IF NOT EXISTS personal_note TEXT,
            ADD COLUMN IF NOT EXISTS is_bookmarked BOOLEAN NOT NULL DEFAULT FALSE
        """
    )
    op.execute(
        """
        ALTER TABLE quiz_results
            ADD COLUMN IF NOT EXISTS topic VARCHAR(50)
        """
    )
    op.execute(
        """
        CREATE INDEX IF NOT EXISTS idx_vocab_bookmark
        ON vocabularies (user_id, is_bookmarked)
        """
    )


def downgrade() -> None:
    op.execute("DROP INDEX IF EXISTS idx_vocab_bookmark")
    op.execute("ALTER TABLE quiz_results DROP COLUMN IF EXISTS topic")
    op.execute(
        """
        ALTER TABLE vocabularies
            DROP COLUMN IF EXISTS is_bookmarked,
            DROP COLUMN IF EXISTS personal_note,
            DROP COLUMN IF EXISTS review_interval
        """
    )
