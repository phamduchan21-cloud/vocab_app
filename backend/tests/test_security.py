import base64
import json

import pytest
from fastapi import HTTPException
from fastapi.security import HTTPAuthorizationCredentials

from core.security import get_current_user
from services.auth_service import AuthService


def _token(payload: dict) -> str:
    encoded = base64.urlsafe_b64encode(json.dumps(payload).encode()).decode()
    return f"header.{encoded.rstrip('=')}.signature"


@pytest.mark.asyncio
async def test_user_sync_failure_is_not_reported_as_invalid_session(monkeypatch):
    async def sync_failure(*_):
        return None

    monkeypatch.setattr(AuthService, "get_or_create_user", sync_failure)
    credentials = HTTPAuthorizationCredentials(
        scheme="Bearer",
        credentials=_token({"sub": "user-id", "email": "user@example.com"}),
    )

    with pytest.raises(HTTPException) as exc_info:
        await get_current_user(credentials=credentials, db=object())

    assert exc_info.value.status_code == 503
