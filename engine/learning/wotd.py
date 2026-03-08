"""
LexiCore — Word of the Day (v5.1)
===================================
- Reservoir Sampling with O(n) traversal, O(1) memory
- 2-hour rotation mode: changes word every 2 hours based on daytime
- Online mode: fetches curated interesting words
"""

from __future__ import annotations

import random
from typing import Callable
from datetime import datetime, date


def reservoir_sample(
    word_iterator: Callable[[], list[str]],
    is_learned: Callable[[str], bool] | None = None,
    seed: int | None = None,
) -> str | None:
    """Select one uniformly random word from *word_iterator*, skipping learned words."""
    rng = random.Random(seed)
    chosen: str | None = None
    count = 0

    for word in word_iterator():
        if is_learned and is_learned(word):
            continue
        count += 1
        if rng.randint(1, count) == 1:
            chosen = word

    return chosen


def get_word_of_the_day(
    word_iterator: Callable[[], list[str]],
    is_learned: Callable[[str], bool] | None = None,
) -> str | None:
    """Deterministic daily WOTD — same word all day, changes at midnight."""
    today_seed = int(date.today().isoformat().replace("-", ""))
    return reservoir_sample(word_iterator, is_learned, seed=today_seed)


def get_wotd_for_period(
    word_iterator: Callable[[], list[str]],
    is_learned: Callable[[str], bool] | None = None,
    hours: int = 2,
) -> str | None:
    """WOTD that rotates every N hours.
    
    Seed = YYYYMMDD * 100 + (hour // hours), so with hours=2:
    - 00:00-01:59 → period 0
    - 02:00-03:59 → period 1
    - ...
    - 22:00-23:59 → period 11
    """
    now = datetime.now()
    day_part = int(now.strftime("%Y%m%d"))
    period = now.hour // max(hours, 1)
    seed = day_part * 100 + period
    return reservoir_sample(word_iterator, is_learned, seed=seed)


# Curated interesting words for online WOTD
CURATED_WORDS = [
    "serendipity", "ephemeral", "luminous", "ethereal", "petrichor",
    "mellifluous", "ineffable", "sonder", "vellichor", "apricity",
    "solitude", "wanderlust", "euphoria", "resilience", "nostalgia",
    "eloquence", "tranquil", "paradigm", "enigmatic", "ubiquitous",
    "epiphany", "cacophony", "azure", "bucolic", "chrysalis",
    "diaphanous", "effervescent", "felicity", "halcyon", "incandescent",
    "juxtapose", "kinetic", "labyrinthine", "magnanimous", "nebulous",
    "opulent", "panacea", "quintessential", "reverie", "sanguine",
    "tenacious", "umbra", "verisimilitude", "whimsical", "xenial",
    "yearning", "zenith", "audacious", "benevolent", "celestial",
    "demure", "ebullient", "fantastical", "gossamer", "harmony",
    "iridescent", "jovial", "kaleidoscope", "languid", "mercurial",
    "nirvana", "oblivion", "paradox", "quixotic", "rapture",
    "sublime", "tempest", "unravel", "vivacious", "wistful",
]


def get_curated_wotd(hours: int = 2) -> str:
    """Return a curated word that rotates every N hours."""
    now = datetime.now()
    day_part = int(now.strftime("%Y%m%d"))
    period = now.hour // max(hours, 1)
    seed = day_part * 100 + period
    rng = random.Random(seed)
    return rng.choice(CURATED_WORDS)
