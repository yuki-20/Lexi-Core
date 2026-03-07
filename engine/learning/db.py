"""
LexiCore — SQLite User Progress Database (v3.0)
=================================================
Manages ``user_progress.db`` for ACID-compliant storage of:
  - search history
  - spaced-repetition review schedule
  - streak / EXP data
  - saved words (deck)
  - flashcard decks & cards
  - quiz results & answers
  - imported files
  - user profile & settings
  - pet unlocks
"""

from __future__ import annotations

import json
import random
import sqlite3
from contextlib import contextmanager
from datetime import datetime, date
from pathlib import Path
from typing import Any, Generator

from engine.config import DB_PATH


_SCHEMA = """
-- ── Original tables ──────────────────────────────────────────────

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
    source_file TEXT,
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
    date_key    TEXT    PRIMARY KEY,
    words_learned INTEGER NOT NULL DEFAULT 0,
    searches     INTEGER NOT NULL DEFAULT 0,
    exp_earned   INTEGER NOT NULL DEFAULT 0
);

-- ── v3.0 — Flashcard decks ──────────────────────────────────────

CREATE TABLE IF NOT EXISTS flashcard_decks (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    name        TEXT    NOT NULL,
    source      TEXT,                                -- 'manual', 'imported', 'saved'
    source_file TEXT,                                -- original filename if imported
    created_at  TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS flashcard_cards (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    deck_id     INTEGER NOT NULL REFERENCES flashcard_decks(id) ON DELETE CASCADE,
    word        TEXT    NOT NULL,
    definition  TEXT,
    mastery     INTEGER NOT NULL DEFAULT 0,          -- 0-5 comfort level
    times_seen  INTEGER NOT NULL DEFAULT 0,
    times_correct INTEGER NOT NULL DEFAULT 0,
    created_at  TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- ── v3.0 — Quiz results ─────────────────────────────────────────

CREATE TABLE IF NOT EXISTS quiz_results (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    deck_id     INTEGER REFERENCES flashcard_decks(id),
    total_q     INTEGER NOT NULL,
    correct     INTEGER NOT NULL,
    score_pct   REAL    NOT NULL,
    duration_s  REAL,
    taken_at    TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS quiz_answers (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    quiz_id     INTEGER NOT NULL REFERENCES quiz_results(id) ON DELETE CASCADE,
    word        TEXT    NOT NULL,
    user_answer TEXT,
    correct_answer TEXT  NOT NULL,
    is_correct  INTEGER NOT NULL DEFAULT 0,
    explanation TEXT
);

-- ── v3.0 — Imported files ────────────────────────────────────────

CREATE TABLE IF NOT EXISTS imported_files (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    filename    TEXT    NOT NULL,
    word_count  INTEGER NOT NULL DEFAULT 0,
    imported_at TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- ── v3.0 — User profile ─────────────────────────────────────────

CREATE TABLE IF NOT EXISTS user_profile (
    key         TEXT    PRIMARY KEY,
    value       TEXT
);

-- ── v3.0 — Pet unlocks ──────────────────────────────────────────

CREATE TABLE IF NOT EXISTS pet_unlocks (
    pet_id      TEXT    PRIMARY KEY,                 -- 'ember_fox', 'volt_owl', etc.
    unlocked_at TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- ── v3.1 — Projects ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS projects (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    name        TEXT    NOT NULL,
    description TEXT    DEFAULT '',
    color       TEXT    DEFAULT '#7C4DFF',
    icon        TEXT    DEFAULT 'folder',
    created_at  TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- ── Indexes ──────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_search_word ON search_history(word);
CREATE INDEX IF NOT EXISTS idx_review_next ON review_schedule(next_review);
CREATE INDEX IF NOT EXISTS idx_cards_deck ON flashcard_cards(deck_id);
CREATE INDEX IF NOT EXISTS idx_quiz_deck ON quiz_results(deck_id);
CREATE INDEX IF NOT EXISTS idx_answers_quiz ON quiz_answers(quiz_id);
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
        # ── Migrations for existing DBs ──
        # ALTER TABLE won't error if we catch it; new columns may not exist in old DBs
        migrations = [
            "ALTER TABLE saved_words ADD COLUMN source_file TEXT",
            "ALTER TABLE saved_words ADD COLUMN audio_path TEXT",
            "ALTER TABLE saved_words ADD COLUMN image_path TEXT",
            "ALTER TABLE streaks ADD COLUMN exp_earned INTEGER NOT NULL DEFAULT 0",
        ]
        for sql in migrations:
            try:
                conn.execute(sql)
            except Exception:
                pass  # column already exists, safe to ignore
        conn.commit()
        conn.close()

    # ── Search History ────────────────────────────────────────────────

    def log_search(self, word: str) -> None:
        with self._cursor() as cur:
            cur.execute("INSERT INTO search_history (word) VALUES (?)", (word,))
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
                  image_path: str | None = None,
                  source_file: str | None = None) -> None:
        with self._cursor() as cur:
            cur.execute(
                "INSERT OR REPLACE INTO saved_words "
                "(word, definition, audio_path, image_path, source_file) "
                "VALUES (?, ?, ?, ?, ?)",
                (word, definition, audio_path, image_path, source_file),
            )

    def get_saved_words(self) -> list[dict[str, Any]]:
        with self._cursor() as cur:
            cur.execute("SELECT * FROM saved_words ORDER BY saved_at DESC")
            return [dict(row) for row in cur.fetchall()]

    def delete_saved_word(self, word: str) -> bool:
        with self._cursor() as cur:
            cur.execute("DELETE FROM saved_words WHERE word = ?", (word,))
            return cur.rowcount > 0

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

    # ══════════════════════════════════════════════════════════════════
    # v3.0 — FLASHCARD DECKS & CARDS
    # ══════════════════════════════════════════════════════════════════

    def create_deck(self, name: str, source: str = "manual",
                    source_file: str | None = None) -> int:
        with self._cursor() as cur:
            cur.execute(
                "INSERT INTO flashcard_decks (name, source, source_file) VALUES (?, ?, ?)",
                (name, source, source_file),
            )
            return cur.lastrowid  # type: ignore

    def get_decks(self) -> list[dict[str, Any]]:
        with self._cursor() as cur:
            cur.execute(
                "SELECT d.*, "
                "  (SELECT COUNT(*) FROM flashcard_cards WHERE deck_id = d.id) as card_count, "
                "  (SELECT COALESCE(AVG(mastery), 0) FROM flashcard_cards WHERE deck_id = d.id) as avg_mastery "
                "FROM flashcard_decks d ORDER BY d.created_at DESC"
            )
            return [dict(row) for row in cur.fetchall()]

    def get_deck(self, deck_id: int) -> dict[str, Any] | None:
        with self._cursor() as cur:
            cur.execute("SELECT * FROM flashcard_decks WHERE id = ?", (deck_id,))
            row = cur.fetchone()
            return dict(row) if row else None

    def delete_deck(self, deck_id: int) -> bool:
        with self._cursor() as cur:
            cur.execute("DELETE FROM flashcard_decks WHERE id = ?", (deck_id,))
            return cur.rowcount > 0

    def add_card(self, deck_id: int, word: str,
                 definition: str | None = None) -> int:
        with self._cursor() as cur:
            cur.execute(
                "INSERT INTO flashcard_cards (deck_id, word, definition) VALUES (?, ?, ?)",
                (deck_id, word, definition),
            )
            return cur.lastrowid  # type: ignore

    def get_cards(self, deck_id: int) -> list[dict[str, Any]]:
        with self._cursor() as cur:
            cur.execute(
                "SELECT * FROM flashcard_cards WHERE deck_id = ? ORDER BY id",
                (deck_id,),
            )
            return [dict(row) for row in cur.fetchall()]

    def update_card_mastery(self, card_id: int, correct: bool) -> None:
        with self._cursor() as cur:
            cur.execute(
                "UPDATE flashcard_cards SET "
                "times_seen = times_seen + 1, "
                "times_correct = times_correct + ?, "
                "mastery = MIN(5, mastery + ?) "
                "WHERE id = ?",
                (1 if correct else 0, 1 if correct else -1, card_id),
            )

    def delete_card(self, card_id: int) -> bool:
        with self._cursor() as cur:
            cur.execute("DELETE FROM flashcard_cards WHERE id = ?", (card_id,))
            return cur.rowcount > 0

    # ══════════════════════════════════════════════════════════════════
    # v3.0 — QUIZ SYSTEM
    # ══════════════════════════════════════════════════════════════════

    def create_quiz_result(self, deck_id: int | None, total_q: int,
                           correct: int, score_pct: float,
                           duration_s: float | None = None) -> int:
        with self._cursor() as cur:
            cur.execute(
                "INSERT INTO quiz_results (deck_id, total_q, correct, score_pct, duration_s) "
                "VALUES (?, ?, ?, ?, ?)",
                (deck_id, total_q, correct, score_pct, duration_s),
            )
            # Award EXP: 10 per correct + bonus for perfect
            exp = correct * 10
            if score_pct >= 100.0:
                exp += 50  # perfect bonus
            self.add_exp(exp, words_learned=correct)
            return cur.lastrowid  # type: ignore

    def add_quiz_answer(self, quiz_id: int, word: str,
                        user_answer: str | None, correct_answer: str,
                        is_correct: bool, explanation: str | None = None) -> None:
        with self._cursor() as cur:
            cur.execute(
                "INSERT INTO quiz_answers "
                "(quiz_id, word, user_answer, correct_answer, is_correct, explanation) "
                "VALUES (?, ?, ?, ?, ?, ?)",
                (quiz_id, word, user_answer, correct_answer,
                 1 if is_correct else 0, explanation),
            )

    def get_quiz_history(self, limit: int = 20) -> list[dict[str, Any]]:
        with self._cursor() as cur:
            cur.execute(
                "SELECT qr.*, fd.name as deck_name "
                "FROM quiz_results qr "
                "LEFT JOIN flashcard_decks fd ON qr.deck_id = fd.id "
                "ORDER BY qr.taken_at DESC LIMIT ?",
                (limit,),
            )
            return [dict(row) for row in cur.fetchall()]

    def get_quiz_answers(self, quiz_id: int) -> list[dict[str, Any]]:
        with self._cursor() as cur:
            cur.execute(
                "SELECT * FROM quiz_answers WHERE quiz_id = ? ORDER BY id",
                (quiz_id,),
            )
            return [dict(row) for row in cur.fetchall()]

    def get_perfect_quiz_count(self) -> int:
        """Count quizzes with 100% score."""
        with self._cursor() as cur:
            cur.execute(
                "SELECT COUNT(*) as cnt FROM quiz_results WHERE score_pct >= 100.0"
            )
            return cur.fetchone()["cnt"]

    def generate_quiz(self, words: list[dict], count: int = 10) -> list[dict]:
        """Generate multiple-choice questions from word list.

        Each item: {word, correct_answer, correct_index, options: [4 choices], explanation}
        """
        if len(words) < 4:
            return []

        random.shuffle(words)
        selected = words[:count]
        questions = []

        for item in selected:
            word = item["word"]
            correct = item.get("definition", "")

            # Pick 3 wrong answers from other words
            others = [w for w in words if w["word"] != word and w.get("definition")]
            random.shuffle(others)
            wrong = [o.get("definition", "") for o in others[:3]]

            options = wrong + [correct]
            random.shuffle(options)

            questions.append({
                "word": word,
                "correct_answer": correct,
                "correct_index": options.index(correct),
                "options": options,
                "explanation": f"'{word}' means: {correct}",
            })

        return questions

    # ══════════════════════════════════════════════════════════════════
    # v3.0 — IMPORTED FILES
    # ══════════════════════════════════════════════════════════════════

    def add_imported_file(self, filename: str, word_count: int) -> int:
        with self._cursor() as cur:
            cur.execute(
                "INSERT INTO imported_files (filename, word_count) VALUES (?, ?)",
                (filename, word_count),
            )
            return cur.lastrowid  # type: ignore

    def get_imported_files(self) -> list[dict[str, Any]]:
        with self._cursor() as cur:
            cur.execute(
                "SELECT * FROM imported_files ORDER BY imported_at DESC"
            )
            return [dict(row) for row in cur.fetchall()]

    def delete_imported_file(self, file_id: int) -> bool:
        """Delete imported file record and associated saved words."""
        with self._cursor() as cur:
            cur.execute("SELECT filename FROM imported_files WHERE id = ?", (file_id,))
            row = cur.fetchone()
            if not row:
                return False
            filename = row["filename"]
            cur.execute(
                "DELETE FROM saved_words WHERE source_file = ?", (filename,)
            )
            cur.execute("DELETE FROM imported_files WHERE id = ?", (file_id,))
            return True

    def get_words_by_source(self, source_file: str) -> list[dict[str, Any]]:
        with self._cursor() as cur:
            cur.execute(
                "SELECT * FROM saved_words WHERE source_file = ? ORDER BY word",
                (source_file,),
            )
            return [dict(row) for row in cur.fetchall()]

    # ══════════════════════════════════════════════════════════════════
    # v3.0 — USER PROFILE
    # ══════════════════════════════════════════════════════════════════

    def get_profile(self) -> dict[str, str]:
        with self._cursor() as cur:
            cur.execute("SELECT key, value FROM user_profile")
            return {row["key"]: row["value"] for row in cur.fetchall()}

    def set_profile(self, key: str, value: str) -> None:
        with self._cursor() as cur:
            cur.execute(
                "INSERT OR REPLACE INTO user_profile (key, value) VALUES (?, ?)",
                (key, value),
            )

    def get_display_name(self) -> str:
        profile = self.get_profile()
        return profile.get("display_name", "Learner")

    # ══════════════════════════════════════════════════════════════════
    # v3.0 — PET UNLOCKS
    # ══════════════════════════════════════════════════════════════════

    # Pet definitions
    PETS = {
        "ember_fox":    {"name": "Ember Fox",    "emoji": "fox",   "streak_req": 7,   "desc": "A fiery companion for dedicated learners"},
        "volt_owl":     {"name": "Volt Owl",     "emoji": "owl",   "streak_req": 30,  "desc": "Wisdom comes to those who persist"},
        "aqua_dragon":  {"name": "Aqua Dragon",  "emoji": "dragon","streak_req": 100, "desc": "A legendary creature of unstoppable learners"},
        "prisma":       {"name": "Prisma",        "emoji": "unicorn","streak_req": 0,  "desc": "A mythical glass unicorn -- for quiz perfectionists", "requires_perfect_quizzes": 3},
    }

    def get_unlocked_pets(self) -> list[dict[str, Any]]:
        with self._cursor() as cur:
            cur.execute("SELECT * FROM pet_unlocks ORDER BY unlocked_at")
            return [dict(row) for row in cur.fetchall()]

    def unlock_pet(self, pet_id: str) -> bool:
        """Unlock a pet. Returns True if newly unlocked."""
        with self._cursor() as cur:
            cur.execute("SELECT 1 FROM pet_unlocks WHERE pet_id = ?", (pet_id,))
            if cur.fetchone():
                return False  # already unlocked
            cur.execute(
                "INSERT INTO pet_unlocks (pet_id) VALUES (?)", (pet_id,)
            )
            return True

    def check_pet_eligibility(self) -> list[str]:
        """Check which pets should be unlocked based on current progress."""
        streak = self.get_streak_days()
        perfect_quizzes = self.get_perfect_quiz_count()
        unlocked = {p["pet_id"] for p in self.get_unlocked_pets()}

        newly_eligible = []
        for pet_id, info in self.PETS.items():
            if pet_id in unlocked:
                continue
            if info.get("requires_perfect_quizzes"):
                if perfect_quizzes >= info["requires_perfect_quizzes"]:
                    newly_eligible.append(pet_id)
            elif streak >= info["streak_req"]:
                newly_eligible.append(pet_id)

        return newly_eligible

    # ══════════════════════════════════════════════════════════════════
    # v3.0 — PERFORMANCE ANALYTICS
    # ══════════════════════════════════════════════════════════════════

    def get_performance_summary(self) -> dict[str, Any]:
        """Aggregate performance across quizzes, searches, and streaks."""
        with self._cursor() as cur:
            # Quiz stats
            cur.execute(
                "SELECT COUNT(*) as total_quizzes, "
                "COALESCE(AVG(score_pct), 0) as avg_score, "
                "COALESCE(MAX(score_pct), 0) as best_score, "
                "COALESCE(SUM(correct), 0) as total_correct, "
                "COALESCE(SUM(total_q), 0) as total_questions "
                "FROM quiz_results"
            )
            quiz = dict(cur.fetchone())

            # Search stats
            cur.execute("SELECT COUNT(*) as total_searches FROM search_history")
            searches = cur.fetchone()["total_searches"]

            # Saved words count
            cur.execute("SELECT COUNT(*) as total_saved FROM saved_words")
            saved = cur.fetchone()["total_saved"]

            # Flashcard stats
            cur.execute(
                "SELECT COUNT(*) as total_cards, "
                "COALESCE(AVG(mastery), 0) as avg_mastery, "
                "COALESCE(SUM(times_seen), 0) as total_reviews "
                "FROM flashcard_cards"
            )
            cards = dict(cur.fetchone())

            # Streak stats
            cur.execute(
                "SELECT COUNT(*) as active_days FROM streaks"
            )
            active_days = cur.fetchone()["active_days"]

        return {
            "quiz": quiz,
            "total_searches": searches,
            "total_saved": saved,
            "flashcards": cards,
            "streak_days": self.get_streak_days(),
            "active_days": active_days,
            "total_exp": self.get_total_exp(),
        }

    # ── Projects ─────────────────────────────────────────────────

    def get_projects(self) -> list[dict]:
        with self._cursor() as cur:
            cur.execute(
                "SELECT id, name, description, color, icon, created_at FROM projects ORDER BY created_at DESC"
            )
            projects = [dict(r) for r in cur.fetchall()]
            for p in projects:
                cur.execute(
                    "SELECT COUNT(*) as cnt FROM flashcard_decks WHERE source = ?",
                    (f"project:{p['id']}",)
                )
                p["deck_count"] = cur.fetchone()["cnt"]
                cur.execute(
                    "SELECT COUNT(*) as cnt FROM quiz_results WHERE deck_id IN "
                    "(SELECT id FROM flashcard_decks WHERE source = ?)",
                    (f"project:{p['id']}",)
                )
                p["quiz_count"] = cur.fetchone()["cnt"]
            return projects

    def create_project(self, name: str, description: str = "", color: str = "#7C4DFF", icon: str = "folder") -> int:
        with self._cursor() as cur:
            cur.execute(
                "INSERT INTO projects (name, description, color, icon) VALUES (?, ?, ?, ?)",
                (name, description, color, icon)
            )
            return cur.lastrowid

    def update_project(self, project_id: int, **kwargs) -> bool:
        allowed = {"name", "description", "color", "icon"}
        updates = {k: v for k, v in kwargs.items() if k in allowed}
        if not updates:
            return False
        set_clause = ", ".join(f"{k} = ?" for k in updates)
        values = list(updates.values()) + [project_id]
        with self._cursor() as cur:
            cur.execute(f"UPDATE projects SET {set_clause} WHERE id = ?", values)
        return True

    def delete_project(self, project_id: int) -> bool:
        with self._cursor() as cur:
            cur.execute(
                "DELETE FROM flashcard_cards WHERE deck_id IN "
                "(SELECT id FROM flashcard_decks WHERE source = ?)",
                (f"project:{project_id}",)
            )
            cur.execute(
                "DELETE FROM flashcard_decks WHERE source = ?",
                (f"project:{project_id}",)
            )
            cur.execute("DELETE FROM projects WHERE id = ?", (project_id,))
        return True

    def get_project(self, project_id: int) -> dict | None:
        with self._cursor() as cur:
            cur.execute(
                "SELECT id, name, description, color, icon, created_at FROM projects WHERE id = ?",
                (project_id,)
            )
            row = cur.fetchone()
            if not row:
                return None
            p = dict(row)
            cur.execute(
                "SELECT id, name, source, created_at FROM flashcard_decks WHERE source = ?",
                (f"project:{project_id}",)
            )
            p["decks"] = [dict(r) for r in cur.fetchall()]
            return p
