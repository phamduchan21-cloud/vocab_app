import asyncio

import pytest

from core.config import settings
from services.ai_service import (
    AIProvider,
    AIProviderError,
    AIService,
    AIUnavailableError,
    GeminiProvider,
    XAIProvider,
)


class FakeProvider(AIProvider):
    def __init__(self, name, *, result=None, error=None):
        self.provider_name = name
        self.result = result
        self.error = error
        self.calls = 0

    async def _result(self):
        self.calls += 1
        if self.error:
            raise self.error
        return self.result

    async def generate_quiz(self, *_args, **_kwargs):
        return await self._result()

    async def generate_mock_questions(self, *_args, **_kwargs):
        return await self._result()

    async def chat(self, *_args, **_kwargs):
        return await self._result()

    async def explain_word(self, *_args, **_kwargs):
        return await self._result()


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


@pytest.mark.asyncio
async def test_service_falls_back_to_next_provider():
    primary = FakeProvider("primary", error=AIProviderError("quota_exhausted"))
    fallback = FakeProvider(
        "fallback",
        result={"reply": "Fallback works", "suggestions": []},
    )
    service = AIService(providers=[primary, fallback])

    result = await service.chat("Hello")

    assert result["reply"] == "Fallback works"
    assert primary.calls == 1
    assert fallback.calls == 1
    snapshot = service.health_snapshot()
    assert snapshot["providers"][0]["last_error_code"] == "quota_exhausted"
    assert snapshot["providers"][1]["successes"] == 1


@pytest.mark.asyncio
async def test_circuit_opens_and_skips_repeatedly_failing_provider(monkeypatch):
    monkeypatch.setattr(settings, "AI_CIRCUIT_FAILURE_THRESHOLD", 2)
    monkeypatch.setattr(settings, "AI_CIRCUIT_RECOVERY_SECONDS", 60)
    primary = FakeProvider("primary", error=AIProviderError("provider_timeout"))
    fallback = FakeProvider(
        "fallback",
        result={"reply": "Fallback works", "suggestions": []},
    )
    service = AIService(providers=[primary, fallback])

    await service.chat("one")
    await service.chat("two")
    await service.chat("three")

    assert primary.calls == 2
    assert fallback.calls == 3
    assert service.health_snapshot()["providers"][0]["state"] == "open"


@pytest.mark.asyncio
async def test_all_providers_failed_returns_safe_service_error():
    service = AIService(
        providers=[FakeProvider("broken", error=RuntimeError("secret-value"))]
    )

    with pytest.raises(AIUnavailableError) as exc_info:
        await service.chat("Hello")

    assert exc_info.value.code == "ai_unavailable"
    assert "secret-value" not in str(exc_info.value)


@pytest.mark.asyncio
async def test_no_provider_is_reported_as_unconfigured():
    service = AIService(providers=[])

    assert service.health_snapshot() == {
        "status": "unconfigured",
        "provider_count": 0,
        "providers": [],
    }
    with pytest.raises(AIUnavailableError):
        await service.chat("Hello")


@pytest.mark.asyncio
async def test_gemini_uses_module_parsers_for_chat_and_quiz(monkeypatch):
    provider = GeminiProvider()

    async def fake_call(prompt):
        if "multiple-choice" in prompt:
            return (
                '[{"question":"Meaning?","options":["A","B"],'
                '"correctAnswer":"A"}]'
            )
        return '{"reply":"Xin chao","suggestions":["Hoc tiep"]}'

    monkeypatch.setattr(provider, "_call", fake_call)

    chat = await provider.chat("Hello", {})
    questions = await provider.generate_quiz(
        [{"word": "hello", "meaning": "xin chao"}],
        1,
        "greetings",
        "beginner",
    )

    assert chat["reply"] == "Xin chao"
    assert questions[0]["correctAnswer"] == "A"


@pytest.mark.asyncio
async def test_invalid_provider_output_triggers_fallback(monkeypatch):
    primary = GeminiProvider()

    async def invalid_call(_prompt):
        return "not-json"

    monkeypatch.setattr(primary, "_call", invalid_call)
    fallback = FakeProvider(
        "fallback",
        result={"reply": "Recovered", "suggestions": []},
    )
    service = AIService(providers=[primary, fallback])

    result = await service.chat("Hello")

    assert result["reply"] == "Recovered"
    assert service.health_snapshot()["providers"][0]["last_error_code"] == (
        "invalid_response"
    )


@pytest.mark.asyncio
async def test_provider_timeout_uses_fallback_within_request_budget(monkeypatch):
    class SlowProvider(FakeProvider):
        async def chat(self, *_args, **_kwargs):
            self.calls += 1
            await asyncio.sleep(0.1)
            return {"reply": "Too late", "suggestions": []}

    monkeypatch.setattr(settings, "AI_PROVIDER_TIMEOUT_SECONDS", 0.01)
    monkeypatch.setattr(settings, "AI_REQUEST_TIMEOUT_SECONDS", 0.08)
    fallback = FakeProvider(
        "fallback",
        result={"reply": "Recovered quickly", "suggestions": []},
    )
    service = AIService(providers=[SlowProvider("slow"), fallback])

    result = await service.chat("Hello")

    assert result["reply"] == "Recovered quickly"
    assert service.health_snapshot()["providers"][0]["last_error_code"] == (
        "provider_timeout"
    )
