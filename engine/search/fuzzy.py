"""
LexiCore — Fuzzy Matching
==========================
Levenshtein distance for typo correction + Metaphone 3 for phonetic matching.
"""

from __future__ import annotations

from metaphone import doublemetaphone
from Levenshtein import distance as lev_distance

from engine.config import FUZZY_THRESHOLD


def levenshtein_match(query: str, candidates: list[str],
                      threshold: int = FUZZY_THRESHOLD) -> list[tuple[str, int]]:
    """Return candidates within *threshold* edit-distance of *query*.

    Results are sorted by distance (closest first).
    """
    q = query.lower()
    matches: list[tuple[str, int]] = []
    for word in candidates:
        d = lev_distance(q, word.lower())
        if d <= threshold:
            matches.append((word, d))
    matches.sort(key=lambda x: x[1])
    return matches


def phonetic_match(query: str, candidates: list[str]) -> list[str]:
    """Return candidates whose Metaphone code matches *query*'s.

    Uses Double Metaphone for better multilingual coverage.
    """
    q_primary, q_secondary = doublemetaphone(query)
    results: list[str] = []

    for word in candidates:
        w_primary, w_secondary = doublemetaphone(word)
        # Match if either primary or secondary codes align
        if (q_primary and q_primary == w_primary) or \
           (q_secondary and q_secondary == w_secondary) or \
           (q_primary and q_primary == w_secondary) or \
           (q_secondary and q_secondary == w_primary):
            results.append(word)

    return results


def fuzzy_search(query: str, candidates: list[str],
                 threshold: int = FUZZY_THRESHOLD) -> list[str]:
    """Combined fuzzy + phonetic search, deduplicated and ranked.

    Priority: exact phonetic matches first, then Levenshtein-close words.
    """
    seen: set[str] = set()
    results: list[str] = []

    # Phonetic matches first
    for word in phonetic_match(query, candidates):
        key = word.lower()
        if key not in seen:
            seen.add(key)
            results.append(word)

    # Then Levenshtein matches
    for word, _dist in levenshtein_match(query, candidates, threshold):
        key = word.lower()
        if key not in seen:
            seen.add(key)
            results.append(word)

    return results
