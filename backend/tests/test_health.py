from fastapi.testclient import TestClient

from main import app


def test_root_returns_api_metadata():
    with TestClient(app) as client:
        response = client.get("/")

    assert response.status_code == 200
    assert response.json() == {
        "message": "SolVocab API",
        "version": "1.1.0",
        "docs": "/docs",
    }
    assert response.headers["X-Request-ID"]


def test_liveness_does_not_require_database():
    request_id = "ci-smoke-test"

    with TestClient(app) as client:
        response = client.get(
            "/health/live",
            headers={"X-Request-ID": request_id},
        )

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
    assert response.headers["X-Request-ID"] == request_id


def test_readiness_checks_database_connection():
    with TestClient(app) as client:
        response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {
        "status": "ok",
        "database": "connected",
    }


def test_ai_health_does_not_make_an_external_request():
    with TestClient(app) as client:
        response = client.get("/health/ai")

    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] in {"ready", "unconfigured"}
    assert payload["providers_configured"] >= payload["providers_ready"]
    assert response.headers["X-Request-ID"]


def test_cors_exposes_request_id_for_frontend_diagnostics():
    with TestClient(app) as client:
        response = client.get(
            "/health/live",
            headers={"Origin": "http://localhost:3000"},
        )

    exposed = response.headers["access-control-expose-headers"].lower()
    assert "x-request-id" in exposed
    assert "x-ai-error-code" in exposed
    assert "retry-after" in exposed


def test_cors_accepts_legacy_production_alias():
    with TestClient(app) as client:
        response = client.options(
            "/api/dashboard",
            headers={
                "Origin": "https://vocab-app-black-xi.vercel.app",
                "Access-Control-Request-Method": "GET",
                "Access-Control-Request-Headers": (
                    "authorization,content-type,x-request-id"
                ),
            },
        )

    assert response.status_code == 200
    assert response.headers["access-control-allow-origin"] == (
        "https://vocab-app-black-xi.vercel.app"
    )
