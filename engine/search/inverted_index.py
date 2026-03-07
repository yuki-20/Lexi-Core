"""
LexiCore — TF-IDF Inverted Index (Reverse Dictionary)
======================================================
Maps every significant word in definitions back to its parent key,
weighted by TF-IDF so "morning greeting" → "hello".
"""

from __future__ import annotations

import math
import re
from collections import defaultdict
from typing import Any


# Common English stop words to exclude from indexing
_STOP_WORDS = frozenset({
    "a", "an", "the", "and", "or", "but", "in", "on", "at", "to", "for",
    "of", "with", "by", "from", "is", "it", "as", "be", "was", "were",
    "been", "are", "this", "that", "which", "who", "whom", "what", "how",
    "not", "no", "nor", "so", "if", "then", "than", "too", "very",
    "can", "will", "just", "do", "has", "have", "had", "may", "shall",
})

_WORD_RE = re.compile(r"[a-zA-Z]{2,}")


class InvertedIndex:
    """TF-IDF inverted index for reverse (definition → word) search."""

    def __init__(self) -> None:
        # term → { word_key: tf_count }
        self._index: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))
        self._doc_count = 0  # total number of word entries indexed
        self._doc_term_counts: dict[str, int] = {}  # word_key → total terms

    # ── Build ─────────────────────────────────────────────────────────

    def add_document(self, word_key: str, definition: dict[str, Any]) -> None:
        """Index all text fields of a *definition* under *word_key*."""
        text_parts: list[str] = []
        for field in ("definitions", "examples", "synonyms"):
            items = definition.get(field, [])
            if isinstance(items, list):
                text_parts.extend(items)
            elif isinstance(items, str):
                text_parts.append(items)

        # Include etymology
        ety = definition.get("etymology", "")
        if ety:
            text_parts.append(ety)

        full_text = " ".join(text_parts).lower()
        tokens = [t for t in _WORD_RE.findall(full_text) if t not in _STOP_WORDS]

        self._doc_count += 1
        self._doc_term_counts[word_key] = len(tokens)

        for token in tokens:
            self._index[token][word_key] += 1

    # ── Search ────────────────────────────────────────────────────────

    def search(self, query: str, limit: int = 10) -> list[tuple[str, float]]:
        """Search definitions by natural language *query*.

        Returns list of (word_key, tfidf_score) sorted by relevance.
        """
        tokens = [t.lower() for t in _WORD_RE.findall(query) if t.lower() not in _STOP_WORDS]
        if not tokens:
            return []

        scores: dict[str, float] = defaultdict(float)

        for token in tokens:
            if token not in self._index:
                continue
            postings = self._index[token]
            idf = math.log(self._doc_count / len(postings)) if postings else 0

            for word_key, tf_count in postings.items():
                total_terms = self._doc_term_counts.get(word_key, 1)
                tf = tf_count / total_terms
                scores[word_key] += tf * idf

        ranked = sorted(scores.items(), key=lambda x: x[1], reverse=True)
        return ranked[:limit]

    # ── Stats ─────────────────────────────────────────────────────────

    @property
    def term_count(self) -> int:
        return len(self._index)

    @property
    def document_count(self) -> int:
        return self._doc_count
