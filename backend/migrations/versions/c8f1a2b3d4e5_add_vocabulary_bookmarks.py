"""Add vocabulary bookmark flag.

Revision ID: c8f1a2b3d4e5
Revises: b57f0c2a91e4
Create Date: 2026-07-23
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "c8f1a2b3d4e5"
down_revision: Union[str, Sequence[str], None] = "b57f0c2a91e4"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "vocabularies",
        sa.Column(
            "is_bookmarked",
            sa.Boolean(),
            nullable=False,
            server_default=sa.false(),
        ),
    )
    op.create_index(
        "idx_vocab_bookmark",
        "vocabularies",
        ["user_id", "is_bookmarked"],
    )


def downgrade() -> None:
    op.drop_index("idx_vocab_bookmark", table_name="vocabularies")
    op.drop_column("vocabularies", "is_bookmarked")
