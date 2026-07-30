import pytest

from core.config import settings
from services.ai_service import AIService, XAIProvider


def test_xai_is_the_primary_provider(monkeypatch):
    monkeypatch.setattr(settings, "XAI_API_KEY", "xai-test-key")
    monkeypatch.setattr(settings, "XAI_MODEL", "grok-test")
    monkeypatch.setattr(settings, "GEMINI_API_KEY", "gemini-test-key")
    monkeypatch.setattr(settings, "OPENAI_API_KEY", "openai-test-key")

    service = AIService()

    assert isinstance(service.providers[0], XAIProvider)
    assert service.providers[0].model == "grok-test"
    assert service.providers[0].base_url == "https://api.x.ai/v1"


@pytest.mark.asyncio
async def test_xai_uses_openai_compatible_endpoint(monkeypatch):
    calls = {}

    class FakeCompletions:
        async def create(self, **kwargs):
            calls["request"] = kwargs
            message = type(
                "Message",
                (),
                {"content": '{"reply":"Xin chao","suggestions":[]}'},
            )
            choice = type("Choice", (), {"message": message()})
            return type("Response", (), {"choices": [choice()]})()

    class FakeAsyncOpenAI:
        def __init__(self, **kwargs):
            calls["client"] = kwargs
            self.chat = type(
                "Chat",
                (),
                {"completions": FakeCompletions()},
            )()

    monkeypatch.setattr(settings, "XAI_API_KEY", "xai-test-key")
    monkeypatch.setattr(settings, "XAI_MODEL", "grok-test")
    monkeypatch.setattr("openai.AsyncOpenAI", FakeAsyncOpenAI)

    result = await XAIProvider().chat("Hello", {"topic": "test"})

    assert calls["client"]["api_key"] == "xai-test-key"
    assert calls["client"]["base_url"] == "https://api.x.ai/v1"
    assert calls["request"]["model"] == "grok-test"
    assert result["reply"] == "Xin chao"
