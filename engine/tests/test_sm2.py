"""Tests for the SM-2 Spaced Repetition Scheduler."""

import tempfile
from pathlib import Path
from engine.learning.db import UserDB
from engine.learning.sm2 import SM2Scheduler


def _temp_db():
    f = tempfile.NamedTemporaryFile(suffix=".db", delete=False)
    f.close()
    return UserDB(Path(f.name))


def test_first_review_correct():
    db = _temp_db()
    sm2 = SM2Scheduler(db)
    result = sm2.review("hello", grade=4)

    assert result["word"] == "hello"
    assert result["repetitions"] == 1
    assert result["interval_days"] == 1
    assert result["ease_factor"] >= 2.0


def test_first_review_incorrect():
    db = _temp_db()
    sm2 = SM2Scheduler(db)
    result = sm2.review("hello", grade=1)

    assert result["repetitions"] == 0  # reset
    assert result["interval_days"] == 1


def test_progressive_intervals():
    db = _temp_db()
    sm2 = SM2Scheduler(db)

    # First correct → 1 day
    r1 = sm2.review("hello", grade=5)
    assert r1["interval_days"] == 1

    # Second correct → 6 days
    r2 = sm2.review("hello", grade=5)
    assert r2["interval_days"] == 6

    # Third correct → 6 * EF
    r3 = sm2.review("hello", grade=5)
    assert r3["interval_days"] > 6


def test_ease_factor_floor():
    db = _temp_db()
    sm2 = SM2Scheduler(db)

    # Many poor grades should not drop EF below 1.3
    for _ in range(10):
        r = sm2.review("hard_word", grade=0)

    assert r["ease_factor"] >= 1.3
