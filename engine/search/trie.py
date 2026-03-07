"""
LexiCore — Trie (Prefix Tree) for Autocomplete
================================================
O(k) search where k = query length.
Loaded from index.data on engine startup.
"""

from __future__ import annotations

from typing import Optional


class TrieNode:
    """Single node in the trie."""
    __slots__ = ("children", "is_end", "word")

    def __init__(self) -> None:
        self.children: dict[str, TrieNode] = {}
        self.is_end: bool = False
        self.word: Optional[str] = None   # preserves original casing


class Trie:
    """Prefix tree for sub-millisecond autocomplete."""

    def __init__(self) -> None:
        self.root = TrieNode()
        self._size = 0

    # ── Insert ────────────────────────────────────────────────────────

    def insert(self, word: str) -> None:
        """Add *word* to the trie.  Case-insensitive internally."""
        node = self.root
        for ch in word.lower():
            if ch not in node.children:
                node.children[ch] = TrieNode()
            node = node.children[ch]
        if not node.is_end:
            self._size += 1
        node.is_end = True
        node.word = word  # store original casing

    # ── Exact search ──────────────────────────────────────────────────

    def search(self, word: str) -> bool:
        """Return True if *word* is in the trie (case-insensitive)."""
        node = self._find_node(word.lower())
        return node is not None and node.is_end

    # ── Autocomplete ──────────────────────────────────────────────────

    def autocomplete(self, prefix: str, limit: int = 10) -> list[str]:
        """Return up to *limit* words starting with *prefix*."""
        node = self._find_node(prefix.lower())
        if node is None:
            return []

        results: list[str] = []
        self._collect(node, results, limit)
        return results

    # ── Bulk load ─────────────────────────────────────────────────────

    def bulk_insert(self, words: list[str]) -> None:
        """Insert many words at once."""
        for w in words:
            self.insert(w)

    # ── Properties ────────────────────────────────────────────────────

    @property
    def size(self) -> int:
        return self._size

    # ── Internals ─────────────────────────────────────────────────────

    def _find_node(self, key: str) -> Optional[TrieNode]:
        node = self.root
        for ch in key:
            if ch not in node.children:
                return None
            node = node.children[ch]
        return node

    def _collect(self, node: TrieNode, results: list[str], limit: int) -> None:
        if len(results) >= limit:
            return
        if node.is_end and node.word is not None:
            results.append(node.word)
        for ch in sorted(node.children):
            if len(results) >= limit:
                return
            self._collect(node.children[ch], results, limit)
