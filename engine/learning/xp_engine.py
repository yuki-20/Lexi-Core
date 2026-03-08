"""
LexiCore — XP & Leveling Engine (v5.5)
========================================
Polynomial level curve with streak multipliers and word mastery badges.

Level formula: XP_required = floor(150 × level^2.0)
  Level 1:      0 XP     Level 5:   3,750 XP
  Level 10: 15,000 XP    Level 20:  60,000 XP
  Level 50: 375,000 XP   Level 100: 1,500,000 XP
  Level 500: 37,500,000  Level 1000: 150,000,000

Max level: 1000

Titles (every 5 levels first 30, then every 10, special at 1000):
  Level 1:   Novice             Level 5:   Word Sprout
  Level 10:  Curious Learner    Level 15:  Word Explorer
  Level 20:  Rising Wordsmith   Level 25:  Skilled Linguist
  Level 30:  Word Connoisseur   Level 40:  Language Scholar
  Level 50:  Vocabulary Artisan Level 60:  Lexicon Guardian
  Level 70:  Word Architect     Level 80:  Syntax Sage
  Level 90:  Polyglot Herald    Level 100: Vocabulary Master
  Level 150: Dictionary Knight  Level 200: Eloquence Lord
  Level 300: Linguistic Emperor Level 500: Grand Lexicographer
  Level 750: Word Titan         Level 1000: ∞ Eternal Lexicon

XP Awards:
  - Search a word:             +3 XP
  - Save a word:               +5 XP
  - Quiz correct answer:      +10 XP
  - Quiz 100% bonus:          +50 XP
  - Daily login:              +10 XP
  - Flashcard review:          +5 XP
  - Complete flashcard deck:  +25 XP

Streak multipliers:
  - 2+ days:  1.1×
  - 7+ days:  1.25×
  - 14+ days: 1.4×
  - 30+ days: 1.6×

Word mastery (per word, based on quiz correct count):
  - Bronze:  3+ correct
  - Silver:  7+ correct
  - Gold:   15+ correct
  - Legend:  30+ correct
"""

from __future__ import annotations
import math
from typing import Any


# ── XP thresholds ──

MAX_LEVEL = 1000

def xp_for_level(level: int) -> int:
    """Total XP required to reach this level."""
    if level <= 1:
        return 0
    return math.floor(150 * (level ** 2.0))


def level_from_xp(total_xp: int) -> int:
    """Current level for given total XP."""
    level = 1
    while level < MAX_LEVEL and xp_for_level(level + 1) <= total_xp:
        level += 1
    return level


def xp_progress(total_xp: int) -> dict[str, Any]:
    """Return current level, XP into level, XP needed for next level."""
    level = level_from_xp(total_xp)
    current_threshold = xp_for_level(level)
    next_threshold = xp_for_level(level + 1) if level < MAX_LEVEL else current_threshold
    xp_into_level = total_xp - current_threshold
    xp_needed = next_threshold - current_threshold

    return {
        "level": level,
        "max_level": MAX_LEVEL,
        "total_xp": total_xp,
        "xp_into_level": xp_into_level,
        "xp_for_next": xp_needed,
        "progress": round(xp_into_level / xp_needed, 3) if xp_needed > 0 else 1.0,
        "title": level_title(level),
    }


# ── Titles ──
# Every 5 levels for first 30, then every 10, special milestones at end

_TITLES = [
    (1000, "∞ Eternal Lexicon"),
    (750,  "Word Titan"),
    (500,  "Grand Lexicographer"),
    (300,  "Linguistic Emperor"),
    (200,  "Eloquence Lord"),
    (150,  "Dictionary Knight"),
    (100,  "Vocabulary Master"),
    (90,   "Polyglot Herald"),
    (80,   "Syntax Sage"),
    (70,   "Word Architect"),
    (60,   "Lexicon Guardian"),
    (50,   "Vocabulary Artisan"),
    (40,   "Language Scholar"),
    (30,   "Word Connoisseur"),
    (25,   "Skilled Linguist"),
    (20,   "Rising Wordsmith"),
    (15,   "Word Explorer"),
    (10,   "Curious Learner"),
    (5,    "Word Sprout"),
    (1,    "Novice"),
]


def level_title(level: int) -> str:
    """Fun title based on level."""
    for threshold, title in _TITLES:
        if level >= threshold:
            return title
    return "Novice"


# ── Streak multiplier ──

def streak_multiplier(streak_days: int) -> float:
    """XP multiplier based on streak length."""
    if streak_days >= 30:
        return 1.6
    elif streak_days >= 14:
        return 1.4
    elif streak_days >= 7:
        return 1.25
    elif streak_days >= 2:
        return 1.1
    return 1.0


# ── XP award amounts (reduced for slower progression) ──

XP_SEARCH = 3
XP_SAVE = 5
XP_QUIZ_CORRECT = 10
XP_QUIZ_PERFECT = 50
XP_DAILY_LOGIN = 10
XP_FLASHCARD = 5
XP_DECK_COMPLETE = 25


def calculate_award(action: str, streak_days: int = 0, **kwargs) -> int:
    """Calculate XP for an action with streak multiplier."""
    base = {
        "search": XP_SEARCH,
        "save": XP_SAVE,
        "quiz_correct": XP_QUIZ_CORRECT,
        "quiz_perfect": XP_QUIZ_PERFECT,
        "daily_login": XP_DAILY_LOGIN,
        "flashcard": XP_FLASHCARD,
        "deck_complete": XP_DECK_COMPLETE,
    }.get(action, 0)

    multiplier = streak_multiplier(streak_days)
    return math.floor(base * multiplier)


# ── Word mastery badges ──

MASTERY_TIERS = {
    "bronze": {"min_correct": 3, "color": "#CD7F32", "emoji": "🥉"},
    "silver": {"min_correct": 7, "color": "#C0C0C0", "emoji": "🥈"},
    "gold":   {"min_correct": 15, "color": "#FFD700", "emoji": "🥇"},
    "legend": {"min_correct": 30, "color": "#FF4500", "emoji": "🏆"},
}


def word_mastery_tier(correct_count: int) -> dict[str, Any] | None:
    """Return the highest mastery tier achieved."""
    result = None
    for tier, info in MASTERY_TIERS.items():
        if correct_count >= info["min_correct"]:
            result = {"tier": tier, **info}
    return result
