"""
LexiCore — SQLite User Progress Database
==========================================
Manages ``user_progress.db`` for ACID-compliant storage of:
  • search history
  • spaced-repetition review schedule
  • streak / EXP data
  • saved words (deck)
"""

from __future__ import annotations

import sqlite3
from contextlib import contextmanager
from datetime import datetime, date
from pathlib import Path
from typing import Any, Generator

from engine.config import DB_PATH


_SCHEMA = """
CREATE TABLE IF NOT EXISTS search_history (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    word        TEXT    NOT NULL,
    searched_at TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS saved_words (
    word        TEXT    PRIMARY KEY,
    definition  TEXT,
    audio_path  TEXT,
    image_path  TEXT,
    saved_at    TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS review_schedule (
    word            TEXT    PRIMARY KEY,
    ease_factor     REAL    NOT NULL DEFAULT 2.5,
    interval_days   INTEGER NOT NULL DEFAULT 1,
    repetitions     INTEGER NOT NULL DEFAULT 0,
    next_review     TEXT    NOT NULL DEFAULT (date('now')),
    last_reviewed   TEXT
);

CREATE TABLE IF NOT EXISTS streaks (
    date_key    TEXT    PRIMARY KEY,   -- ISO date YYYY-MM-DD
    words_learned INTEGER NOT NULL DEFAULT 0,
    searches     INTEGER NOT NULL DEFAULT 0,
    exp_earned   INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_search_word ON search_history(word);
CREATE INDEX IF NOT EXISTS idx_review_next ON review_schedule(next_review);
"""


class UserDB:
    """Thin wrapper around SQLite for user progress tracking."""

    def __init__(self, path: Path | None = None) -> None:
        self.path = path or DB_PATH
        self._init_schema()

    # ── Connection ────────────────────────────────────────────────────

    def _connect(self) -> sqlite3.Connection:
        conn = sqlite3.connect(str(self.path))
        conn.row_factory = sqlite3.Row
        conn.execute("PRAGMA journal_mode=WAL")
        conn.execute("PRAGMA foreign_keys=ON")
        return conn

    @contextmanager
    def _cursor(self) -> Generator[sqlite3.Cursor, None, None]:
        conn = self._connect()
        try:
            cur = conn.cursor()
            yield cur
            conn.commit()
        finally:
            conn.close()

    def _init_schema(self) -> None:
        conn = self._connect()
        conn.executescript(_SCHEMA)
        conn.close()

    # ── Search History ────────────────────────────────────────────────

    def log_search(self, word: str) -> None:
        with self._cursor() as cur:
            cur.execute("INSERT INTO search_history (word) VALUES (?)", (word,))
            # Update daily streak counters
            today = date.today().isoformat()
            cur.execute(
                "INSERT INTO streaks (date_key, searches) VALUES (?, 1) "
                "ON CONFLICT(date_key) DO UPDATE SET searches = searches + 1",
                (today,),
            )

    def get_search_history(self, limit: int = 50) -> list[dict[str, Any]]:
        with self._cursor() as cur:
            cur.execute(
                "SELECT word, searched_at FROM search_history ORDER BY id DESC LIMIT ?",
                (limit,),
            )
            return [dict(row) for row in cur.fetchall()]

    # ── Saved Words (Deck) ────────────────────────────────────────────

    def save_word(self, word: str, definition: str | None = None,
                  audio_path: str | None = None,
                  image_path: str | None = None) -> None:
        with self._cursor() as cur:
            cur.execute(
                "INSERT OR REPLACE INTO saved_words (word, definition, audio_path, image_path) "
                "VALUES (?, ?, ?, ?)",
                (word, definition, audio_path, image_path),
            )

    def get_saved_words(self) -> list[dict[str, Any]]:
        with self._cursor() as cur:
            cur.execute("SELECT * FROM saved_words ORDER BY saved_at DESC")
            return [dict(row) for row in cur.fetchall()]

    def is_saved(self, word: str) -> bool:
        with self._cursor() as cur:
            cur.execute("SELECT 1 FROM saved_words WHERE word = ?", (word,))
            return cur.fetchone() is not None

    # ── Review Schedule (SM-2) ────────────────────────────────────────

    def get_review(self, word: str) -> dict[str, Any] | None:
        with self._cursor() as cur:
            cur.execute("SELECT * FROM review_schedule WHERE word = ?", (word,))
            row = cur.fetchone()
            return dict(row) if row else None

    def upsert_review(self, word: str, ease_factor: float,
                      interval_days: int, repetitions: int,
                      next_review: str) -> None:
        with self._cursor() as cur:
            cur.execute(
                "INSERT INTO review_schedule (word, ease_factor, interval_days, "
                "repetitions, next_review, last_reviewed) "
                "VALUES (?, ?, ?, ?, ?, date('now')) "
                "ON CONFLICT(word) DO UPDATE SET "
                "ease_factor=excluded.ease_factor, interval_days=excluded.interval_days, "
                "repetitions=excluded.repetitions, next_review=excluded.next_review, "
                "last_reviewed=date('now')",
                (word, ease_factor, interval_days, repetitions, next_review),
            )

    def get_due_reviews(self) -> list[dict[str, Any]]:
        with self._cursor() as cur:
            cur.execute(
                "SELECT * FROM review_schedule WHERE next_review <= date('now') "
                "ORDER BY next_review ASC"
            )
            return [dict(row) for row in cur.fetchall()]

    # ── Streaks ───────────────────────────────────────────────────────

    def add_exp(self, exp: int, words_learned: int = 0) -> None:
        today = date.today().isoformat()
        with self._cursor() as cur:
            cur.execute(
                "INSERT INTO streaks (date_key, words_learned, exp_earned) "
                "VALUES (?, ?, ?) "
                "ON CONFLICT(date_key) DO UPDATE SET "
                "words_learned = words_learned + excluded.words_learned, "
                "exp_earned = exp_earned + excluded.exp_earned",
                (today, words_learned, exp),
            )

    def get_streak_days(self) -> int:
        """Count consecutive active days ending today/yesterday."""
        with self._cursor() as cur:
            cur.execute("SELECT date_key FROM streaks ORDER BY date_key DESC")
            rows = cur.fetchall()

        if not rows:
            return 0

        streak = 0
        expected = date.today()
        for row in rows:
            d = date.fromisoformat(row["date_key"])
            if d == expected:
                streak += 1
                expected = date.fromordinal(expected.toordinal() - 1)
            elif d == date.fromordinal(expected.toordinal() - 1):
                # Allow yesterday as start if today has no activity yet
                expected = d
                streak += 1
                expected = date.fromordinal(expected.toordinal() - 1)
            else:
                break

        return streak

    def get_total_exp(self) -> int:
        with self._cursor() as cur:
            cur.execute("SELECT COALESCE(SUM(exp_earned), 0) as total FROM streaks")
            return cur.fetchone()["total"]
