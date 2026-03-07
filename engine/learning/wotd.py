"""
LexiCore — Word of the Day (Reservoir Sampling)
=================================================
O(n) traversal, O(1) memory — mathematically guarantees uniform random selection.
Excludes already-learned words.
"""

from __future__ import annotations

import random
from typing import Callable


def reservoir_sample(
    word_iterator: Callable[[], list[str]],
    is_learned: Callable[[str], bool] | None = None,
    seed: int | None = None,
) -> str | None:
    """Select one uniformly random word from *word_iterator*, skipping learned words.

    Parameters
    ----------
    word_iterator : callable
        Returns a list of all words.
    is_learned : callable, optional
        Function that returns True if a word is already mastered.
    seed : int, optional
        Seed for reproducible daily selection (e.g., hash of today's date).

    Returns
    -------
    A randomly selected unlearned word, or None if all words are learned.
    """
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
    from datetime import date
    today_seed = int(date.today().isoformat().replace("-", ""))
    return reservoir_sample(word_iterator, is_learned, seed=today_seed)
