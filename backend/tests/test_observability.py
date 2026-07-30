import json
import logging

from core.observability import JsonFormatter, request_id_context


def test_json_formatter_includes_ai_telemetry_and_request_id():
    token = request_id_context.set("request-test")
    try:
        record = logging.LogRecord(
            name="test.ai",
            level=logging.WARNING,
            pathname=__file__,
            lineno=10,
            msg="ai_provider_failed",
            args=(),
            exc_info=None,
        )
        record.provider = "xai"
        record.operation = "chat"
        record.outcome = "failure"
        record.error_code = "quota_exhausted"
        record.duration_ms = 123.4

        payload = json.loads(JsonFormatter().format(record))
    finally:
        request_id_context.reset(token)

    assert payload["request_id"] == "request-test"
    assert payload["provider"] == "xai"
    assert payload["operation"] == "chat"
    assert payload["error_code"] == "quota_exhausted"
    assert payload["duration_ms"] == 123.4
