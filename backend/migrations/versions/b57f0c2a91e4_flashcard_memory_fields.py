"""Add flashcard memory fields.

Revision ID: b57f0c2a91e4
Revises: 96087349788c
Create Date: 2026-07-18
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "b57f0c2a91e4"
down_revision: Union[str, Sequence[str], None] = "96087349788c"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "vocabularies",
        sa.Column("review_interval", sa.Integer(), nullable=True, server_default="0"),
    )
    op.add_column(
        "vocabularies",
        sa.Column("personal_note", sa.Text(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("vocabularies", "personal_note")
    op.drop_column("vocabularies", "review_interval")
