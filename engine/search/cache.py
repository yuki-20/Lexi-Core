"""
LexiCore — LRU Cache
=====================
Hash Map + OrderedDict implementation capping at LRU_CAPACITY.
Wraps definition lookups to keep hot words in RAM.
"""

from __future__ import annotations

from collections import OrderedDict
from typing import Any

from engine.config import LRU_CAPACITY


class LRUCache:
    """Least-Recently-Used cache backed by an OrderedDict."""

    def __init__(self, capacity: int = LRU_CAPACITY) -> None:
        self.capacity = capacity
        self._store: OrderedDict[str, Any] = OrderedDict()
        self._hits = 0
        self._misses = 0

    # ── Read ──────────────────────────────────────────────────────────

    def get(self, key: str) -> Any | None:
        """Return cached value or None.  Promotes key to most-recent."""
        if key in self._store:
            self._hits += 1
            self._store.move_to_end(key)
            return self._store[key]
        self._misses += 1
        return None

    # ── Write ─────────────────────────────────────────────────────────

    def put(self, key: str, value: Any) -> None:
        """Insert or update.  Evicts LRU entry if at capacity."""
        if key in self._store:
            self._store.move_to_end(key)
        elif len(self._store) >= self.capacity:
            self._store.popitem(last=False)  # evict oldest
        self._store[key] = value

    # ── Utils ─────────────────────────────────────────────────────────

    def contains(self, key: str) -> bool:
        return key in self._store

    def clear(self) -> None:
        self._store.clear()
        self._hits = 0
        self._misses = 0

    @property
    def size(self) -> int:
        return len(self._store)

    @property
    def hit_rate(self) -> float:
        total = self._hits + self._misses
        return self._hits / total if total > 0 else 0.0

    @property
    def stats(self) -> dict[str, int | float]:
        return {
            "size": self.size,
            "capacity": self.capacity,
            "hits": self._hits,
            "misses": self._misses,
            "hit_rate": round(self.hit_rate, 4),
        }
