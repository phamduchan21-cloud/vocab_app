"""Add user learning preferences.

Revision ID: d9a4e5f6b7c8
Revises: c8f1a2b3d4e5
Create Date: 2026-07-28
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "d9a4e5f6b7c8"
down_revision: Union[str, Sequence[str], None] = "c8f1a2b3d4e5"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column("english_level", sa.String(length=20), nullable=True),
    )
    op.add_column(
        "users",
        sa.Column("learning_goals", sa.JSON(), nullable=True),
    )
    op.add_column(
        "users",
        sa.Column(
            "daily_word_goal",
            sa.Integer(),
            nullable=False,
            server_default="10",
        ),
    )


def downgrade() -> None:
    op.drop_column("users", "daily_word_goal")
    op.drop_column("users", "learning_goals")
    op.drop_column("users", "english_level")
