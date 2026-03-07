"""
LexiCore — XP & Leveling Engine
================================
Polynomial level curve with streak multipliers and word mastery badges.

Level formula: XP_required = floor(100 × level^1.5)
  Level 1:    100 XP     Level 5:   1,118 XP
  Level 10:  3,162 XP    Level 20:  8,944 XP
  Level 50: 35,355 XP    Level 100: 100,000 XP

XP Awards:
  - Search a word:             +5 XP
  - Save a word:              +10 XP
  - Quiz correct answer:      +25 XP
  - Quiz 100% bonus:         +100 XP
  - Daily login:              +15 XP
  - Flashcard review:         +10 XP
  - Complete flashcard deck:  +50 XP

Streak multipliers:
  - 2+ days:  1.2×
  - 7+ days:  1.5×
  - 14+ days: 1.8×
  - 30+ days: 2.0×

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

def xp_for_level(level: int) -> int:
    """Total XP required to reach this level."""
    if level <= 1:
        return 0
    return math.floor(100 * (level ** 1.5))


def level_from_xp(total_xp: int) -> int:
    """Current level for given total XP."""
    level = 1
    while xp_for_level(level + 1) <= total_xp:
        level += 1
    return level


def xp_progress(total_xp: int) -> dict[str, Any]:
    """Return current level, XP into level, XP needed for next level."""
    level = level_from_xp(total_xp)
    current_threshold = xp_for_level(level)
    next_threshold = xp_for_level(level + 1)
    xp_into_level = total_xp - current_threshold
    xp_needed = next_threshold - current_threshold

    return {
        "level": level,
        "total_xp": total_xp,
        "xp_into_level": xp_into_level,
        "xp_for_next": xp_needed,
        "progress": round(xp_into_level / xp_needed, 3) if xp_needed > 0 else 1.0,
        "title": level_title(level),
    }


def level_title(level: int) -> str:
    """Fun title based on level."""
    if level >= 50:
        return "Lexicon Sage"
    elif level >= 40:
        return "Word Architect"
    elif level >= 30:
        return "Vocabulary Master"
    elif level >= 20:
        return "Language Scholar"
    elif level >= 15:
        return "Word Connoisseur"
    elif level >= 10:
        return "Skilled Linguist"
    elif level >= 7:
        return "Rising Wordsmith"
    elif level >= 5:
        return "Curious Learner"
    elif level >= 3:
        return "Word Explorer"
    else:
        return "Novice"


# ── Streak multiplier ──

def streak_multiplier(streak_days: int) -> float:
    """XP multiplier based on streak length."""
    if streak_days >= 30:
        return 2.0
    elif streak_days >= 14:
        return 1.8
    elif streak_days >= 7:
        return 1.5
    elif streak_days >= 2:
        return 1.2
    return 1.0


# ── XP award amounts ──

XP_SEARCH = 5
XP_SAVE = 10
XP_QUIZ_CORRECT = 25
XP_QUIZ_PERFECT = 100
XP_DAILY_LOGIN = 15
XP_FLASHCARD = 10
XP_DECK_COMPLETE = 50


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
