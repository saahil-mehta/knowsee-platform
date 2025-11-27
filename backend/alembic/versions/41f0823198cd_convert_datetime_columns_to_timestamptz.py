"""convert_datetime_columns_to_timestamptz

Revision ID: 41f0823198cd
Revises:
Create Date: 2025-11-25 19:18:30.594802

"""
from typing import Sequence, Union

from alembic import op
from sqlalchemy.dialects.postgresql import TIMESTAMP


# revision identifiers, used by Alembic.
revision: str = '41f0823198cd'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Convert all datetime columns from TIMESTAMP to TIMESTAMP WITH TIME ZONE.

    PostgreSQL automatically converts existing naive timestamps to timestamptz
    by assuming they are in the session timezone (typically UTC).
    """
    # Chat table
    op.alter_column(
        'Chat',
        'createdAt',
        type_=TIMESTAMP(timezone=True),
        existing_type=TIMESTAMP(timezone=False),
        existing_nullable=False
    )

    # Message_v2 table
    op.alter_column(
        'Message_v2',
        'createdAt',
        type_=TIMESTAMP(timezone=True),
        existing_type=TIMESTAMP(timezone=False),
        existing_nullable=False
    )

    # Document table (createdAt is part of composite primary key)
    op.alter_column(
        'Document',
        'createdAt',
        type_=TIMESTAMP(timezone=True),
        existing_type=TIMESTAMP(timezone=False),
        existing_nullable=False
    )

    # Suggestion table - documentCreatedAt (FK reference)
    op.alter_column(
        'Suggestion',
        'documentCreatedAt',
        type_=TIMESTAMP(timezone=True),
        existing_type=TIMESTAMP(timezone=False),
        existing_nullable=False
    )

    # Suggestion table - createdAt
    op.alter_column(
        'Suggestion',
        'createdAt',
        type_=TIMESTAMP(timezone=True),
        existing_type=TIMESTAMP(timezone=False),
        existing_nullable=False
    )

    # Stream table
    op.alter_column(
        'Stream',
        'createdAt',
        type_=TIMESTAMP(timezone=True),
        existing_type=TIMESTAMP(timezone=False),
        existing_nullable=False
    )


def downgrade() -> None:
    """Revert datetime columns back to TIMESTAMP WITHOUT TIME ZONE."""
    op.alter_column(
        'Stream',
        'createdAt',
        type_=TIMESTAMP(timezone=False),
        existing_type=TIMESTAMP(timezone=True),
        existing_nullable=False
    )

    op.alter_column(
        'Suggestion',
        'createdAt',
        type_=TIMESTAMP(timezone=False),
        existing_type=TIMESTAMP(timezone=True),
        existing_nullable=False
    )

    op.alter_column(
        'Suggestion',
        'documentCreatedAt',
        type_=TIMESTAMP(timezone=False),
        existing_type=TIMESTAMP(timezone=True),
        existing_nullable=False
    )

    op.alter_column(
        'Document',
        'createdAt',
        type_=TIMESTAMP(timezone=False),
        existing_type=TIMESTAMP(timezone=True),
        existing_nullable=False
    )

    op.alter_column(
        'Message_v2',
        'createdAt',
        type_=TIMESTAMP(timezone=False),
        existing_type=TIMESTAMP(timezone=True),
        existing_nullable=False
    )

    op.alter_column(
        'Chat',
        'createdAt',
        type_=TIMESTAMP(timezone=False),
        existing_type=TIMESTAMP(timezone=True),
        existing_nullable=False
    )
