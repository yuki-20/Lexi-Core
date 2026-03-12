from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from engine.data.builder import build
from engine.learning.db import UserDB
from engine.learning.sm2 import SM2Scheduler
from engine.learning.streaks import StreakTracker
from engine.main import app, engine


_SAMPLE = Path(__file__).resolve().parent.parent.parent / "scripts" / "sample_dictionary.json"


@pytest.fixture(scope="module", autouse=True)
def setup_dictionary():
    if not _SAMPLE.exists():
        pytest.skip("sample_dictionary.json not found")
    build(str(_SAMPLE))
    engine.load()
    yield


@pytest.fixture
def isolated_client(tmp_path):
    old_db = engine.db
    old_sm2 = engine.sm2
    old_streaks = engine.streaks

    temp_db = UserDB(tmp_path / "user_progress.db")
    engine.db = temp_db
    engine.sm2 = SM2Scheduler(temp_db)
    engine.streaks = StreakTracker(temp_db)

    with TestClient(app) as client:
        yield client

    engine.db = old_db
    engine.sm2 = old_sm2
    engine.streaks = old_streaks


def test_daily_login_awards_only_once_per_day(isolated_client):
    first = isolated_client.post("/api/xp/award", json={"action": "daily_login"})
    second = isolated_client.post("/api/xp/award", json={"action": "daily_login"})

    assert first.status_code == 200
    assert first.json()["awarded"] == 10
    assert first.json()["already_claimed"] is False

    assert second.status_code == 200
    assert second.json()["awarded"] == 0
    assert second.json()["already_claimed"] is True
    assert second.json()["total_xp"] == first.json()["total_xp"]


def test_profile_name_syncs_across_profile_and_welcome(isolated_client):
    profile = isolated_client.get("/api/profile").json()["profile"]
    assert profile["name"] == "Learner"
    assert profile["display_name"] == "Learner"

    resp = isolated_client.put("/api/profile", json={"key": "name", "value": "Yuki"})
    assert resp.status_code == 200

    updated = isolated_client.get("/api/profile").json()["profile"]
    welcome = isolated_client.get("/api/welcome").json()

    assert updated["name"] == "Yuki"
    assert updated["display_name"] == "Yuki"
    assert welcome["name"] == "Yuki"


def test_quiz_submit_awards_xp_updates_quests_and_history(isolated_client):
    answers = [
        {
            "word": "alpha",
            "user_answer": "first",
            "correct_answer": "first",
            "is_correct": True,
        },
        {
            "word": "bravo",
            "user_answer": "second",
            "correct_answer": "second",
            "is_correct": True,
        },
        {
            "word": "charlie",
            "user_answer": "third",
            "correct_answer": "third",
            "is_correct": True,
        },
        {
            "word": "delta",
            "user_answer": "fourth",
            "correct_answer": "fourth",
            "is_correct": True,
        },
        {
            "word": "echo",
            "user_answer": "fifth",
            "correct_answer": "fifth",
            "is_correct": True,
        },
    ]

    resp = isolated_client.post(
        "/api/quiz/submit",
        json={"answers": answers, "duration_s": 42.5},
    )
    data = resp.json()

    assert resp.status_code == 200
    assert data["correct"] == 5
    assert data["xp_awarded"] == 100
    assert data["quest_bonus"] == 75
    assert data["total_xp"] == 175

    quests = isolated_client.get("/api/quests").json()["quests"]
    by_id = {quest["id"]: quest for quest in quests}
    assert by_id["quiz_1"]["progress"] == 1
    assert by_id["quiz_1"]["completed"] is True
    assert by_id["master_10"]["progress"] == 5
    assert by_id["master_10"]["completed"] is False

    history = isolated_client.get("/api/quiz/history").json()["history"]
    assert len(history) == 1
    assert history[0]["created_at"]
    assert history[0]["taken_at"]


def test_achievements_unlock_from_first_search(isolated_client):
    resp = isolated_client.get("/api/search?q=hello")
    assert resp.status_code == 200

    achievements = isolated_client.get("/api/achievements").json()["achievements"]
    by_id = {achievement["id"]: achievement for achievement in achievements}

    assert by_id["first_lookup"]["unlocked"] is True
    assert by_id["first_lookup"]["progress"] == 1
    assert by_id["first_lookup"]["unlocked_at"]


def test_quiz_generation_from_custom_words_requires_real_definitions(isolated_client):
    resp = isolated_client.post(
        "/api/quiz/generate",
        json={
            "words": [
                "zzxxyyqv_1001",
                "zzxxyyqv_1002",
                "zzxxyyqv_1003",
                "zzxxyyqv_1004",
            ],
            "count": 5,
        },
    )

    assert resp.status_code == 400
    assert "definitions" in resp.json()["error"]
