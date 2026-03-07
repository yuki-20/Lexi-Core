"""
LexiCore — SM-2 Spaced Repetition Scheduler
=============================================
Implementation of the SuperMemo-2 algorithm.
Calculates next review date based on user self-grading (0-5).
"""

from __future__ import annotations

from datetime import date, timedelta
from typing import Any

from engine.learning.db import UserDB


def _compute_sm2(
    grade: int,
    repetitions: int,
    ease_factor: float,
    interval: int,
) -> tuple[int, float, int]:
    """Core SM-2 calculation.

    Parameters
    ----------
    grade : int
        User self-assessment 0–5 (3 = correct with difficulty, 5 = perfect).
    repetitions : int
        Current consecutive correct count.
    ease_factor : float
        Current ease factor (≥ 1.3).
    interval : int
        Current interval in days.

    Returns
    -------
    (new_interval, new_ease_factor, new_repetitions)
    """
    if grade >= 3:
        # Correct response
        if repetitions == 0:
            new_interval = 1
        elif repetitions == 1:
            new_interval = 6
        else:
            new_interval = round(interval * ease_factor)
        new_repetitions = repetitions + 1
    else:
        # Incorrect — reset
        new_interval = 1
        new_repetitions = 0

    # Update ease factor
    new_ef = ease_factor + (0.1 - (5 - grade) * (0.08 + (5 - grade) * 0.02))
    new_ef = max(new_ef, 1.3)  # floor at 1.3

    return new_interval, new_ef, new_repetitions


class SM2Scheduler:
    """High-level scheduler wrapping SM-2 + UserDB."""

    def __init__(self, db: UserDB | None = None) -> None:
        self.db = db or UserDB()

    def review(self, word: str, grade: int) -> dict[str, Any]:
        """Grade a word and schedule next review.

        Parameters
        ----------
        word : str
            The word being reviewed.
        grade : int
            User self-grade (0–5).

        Returns
        -------
        dict with keys: word, next_review, interval_days, ease_factor, repetitions
        """
        grade = max(0, min(5, grade))

        existing = self.db.get_review(word)
        if existing:
            reps = existing["repetitions"]
            ef = existing["ease_factor"]
            interval = existing["interval_days"]
        else:
            reps = 0
            ef = 2.5
            interval = 1

        new_interval, new_ef, new_reps = _compute_sm2(grade, reps, ef, interval)
        next_review = (date.today() + timedelta(days=new_interval)).isoformat()

        self.db.upsert_review(word, new_ef, new_interval, new_reps, next_review)

        # Award EXP
        if grade >= 3:
            exp = 10 + (grade - 3) * 5  # 10, 15, 20 EXP for grades 3,4,5
            self.db.add_exp(exp, words_learned=1)

        return {
            "word": word,
            "next_review": next_review,
            "interval_days": new_interval,
            "ease_factor": round(new_ef, 2),
            "repetitions": new_reps,
        }

    def get_due(self) -> list[dict[str, Any]]:
        """Return all words due for review today or earlier."""
        return self.db.get_due_reviews()
