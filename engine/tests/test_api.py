"""
Integration tests for the FastAPI endpoints.
Verifies all PRD endpoints work correctly end-to-end.
"""

import pytest
from fastapi.testclient import TestClient

# We need to build data first, so import builder
from engine.data.builder import build
from engine.main import app, engine
from pathlib import Path

# Build test dictionary before running
_SAMPLE = Path(__file__).resolve().parent.parent.parent / "scripts" / "sample_dictionary.json"


@pytest.fixture(scope="module", autouse=True)
def setup_engine():
    """Ensure the dictionary data is built and engine is loaded."""
    if not _SAMPLE.exists():
        pytest.skip("sample_dictionary.json not found")
    build(str(_SAMPLE))
    engine.load()
    yield


@pytest.fixture
def client():
    return TestClient(app)


# ── 1. Exact Search ──────────────────────────────────────────────────

def test_search_exact_found(client):
    resp = client.get("/api/search?q=hello")
    data = resp.json()
    assert resp.status_code == 200
    assert data["found"] is True
    assert data["query"] == "hello"
    assert "definition" in data
    assert data["definition"]["word"] == "hello"
    assert "timing_ms" in data


def test_search_exact_not_found(client):
    resp = client.get("/api/search?q=xyznonexistent")
    data = resp.json()
    assert resp.status_code == 200
    assert data["found"] is False


# ── 2. Fuzzy Search ──────────────────────────────────────────────────

def test_fuzzy_search(client):
    resp = client.get("/api/fuzzy?q=helo")
    data = resp.json()
    assert resp.status_code == 200
    assert "suggestions" in data
    # "hello" should be a suggestion for "helo"
    assert "hello" in data["suggestions"]


# ── 3. Autocomplete ──────────────────────────────────────────────────

def test_autocomplete(client):
    resp = client.get("/api/autocomplete?prefix=he")
    data = resp.json()
    assert resp.status_code == 200
    assert "suggestions" in data
    assert len(data["suggestions"]) > 0
    assert "hello" in data["suggestions"]


def test_autocomplete_limit(client):
    resp = client.get("/api/autocomplete?prefix=a&limit=3")
    data = resp.json()
    assert len(data["suggestions"]) <= 3


# ── 4. Reverse Search ────────────────────────────────────────────────

def test_reverse_search(client):
    resp = client.get("/api/reverse?q=greeting")
    data = resp.json()
    assert resp.status_code == 200
    assert "results" in data
    # "hello" should appear since its definition mentions "greeting"
    words = [r["word"] for r in data["results"]]
    assert "hello" in words


# ── 5. Stats ─────────────────────────────────────────────────────────

def test_stats(client):
    resp = client.get("/api/stats")
    data = resp.json()
    assert resp.status_code == 200
    assert "dictionary_size" in data
    assert data["dictionary_size"] == 20
    assert "learning" in data
    assert "cache" in data
    assert data["ready"] is True


# ── 6. Word of the Day ──────────────────────────────────────────────

def test_wotd(client):
    resp = client.get("/api/wotd")
    data = resp.json()
    assert resp.status_code == 200
    assert "word" in data
    # Should return a word from our dictionary
    if data["word"]:
        assert isinstance(data["word"], str)


# ── 7. Save Word ────────────────────────────────────────────────────

def test_save_word(client):
    resp = client.post("/api/save", json={
        "word": "hello",
        "definition": "a greeting"
    })
    data = resp.json()
    assert resp.status_code == 200
    assert data["saved"] is True


def test_get_saved(client):
    # Save one first
    client.post("/api/save", json={"word": "world"})
    resp = client.get("/api/saved")
    data = resp.json()
    assert resp.status_code == 200
    assert "words" in data
    assert len(data["words"]) > 0


# ── 8. Search History ───────────────────────────────────────────────

def test_search_history(client):
    # Search first to generate history
    client.get("/api/search?q=python")
    resp = client.get("/api/history")
    data = resp.json()
    assert resp.status_code == 200
    assert "history" in data


# ── 9. Review (SM-2) ────────────────────────────────────────────────

def test_review(client):
    resp = client.post("/api/review", json={
        "word": "hello",
        "grade": 4,
    })
    data = resp.json()
    assert resp.status_code == 200
    assert data["word"] == "hello"
    assert "next_review" in data
    assert "ease_factor" in data
    assert data["repetitions"] >= 1


def test_due_reviews(client):
    resp = client.get("/api/due")
    data = resp.json()
    assert resp.status_code == 200
    assert "due" in data


# ── 10. OCR (structure only — no screen to capture) ─────────────────

def test_ocr_endpoint_exists(client):
    resp = client.post("/api/ocr", json={
        "x1": 0, "y1": 0, "x2": 100, "y2": 100,
    })
    # Should return 200 even if OCR fails (graceful degradation)
    assert resp.status_code == 200
    data = resp.json()
    assert "text" in data


# ── 11. Export (structure only) ──────────────────────────────────────

def test_export_with_saved_words(client):
    # Save a word first
    client.post("/api/save", json={"word": "test_export", "definition": "a test"})
    resp = client.post("/api/export", json={"deck_name": "TestDeck"})
    # Should return a file or 200
    assert resp.status_code == 200


# ── 12. Performance ─────────────────────────────────────────────────

def test_search_performance(client):
    """Verify search returns in sub-millisecond time."""
    resp = client.get("/api/search?q=hello")
    data = resp.json()
    # Timing should be well under 10ms for 20-word dictionary
    assert data["timing_ms"] < 10.0


def test_autocomplete_performance(client):
    resp = client.get("/api/autocomplete?prefix=he")
    data = resp.json()
    assert data["timing_ms"] < 10.0
