"""
LexiCore — Streak Analytics & EXP System
==========================================
Tracks consecutive days of activity and daily EXP earnings.
"""

from __future__ import annotations

from typing import Any

from engine.learning.db import UserDB


class StreakTracker:
    """Convenience wrapper for streak & EXP queries."""

    def __init__(self, db: UserDB | None = None) -> None:
        self.db = db or UserDB()

    def get_stats(self) -> dict[str, Any]:
        """Return a snapshot of the user's learning stats."""
        return {
            "streak_days": self.db.get_streak_days(),
            "total_exp": self.db.get_total_exp(),
        }

    def award(self, exp: int, words_learned: int = 0) -> None:
        """Manually award EXP (used by non-SM2 features)."""
        self.db.add_exp(exp, words_learned)
