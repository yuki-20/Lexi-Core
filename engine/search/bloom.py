"""
LexiCore — Bloom Filter (Zero-Disk Fast-Fail)
===============================================
O(1) probabilistic membership test.
If ``might_contain`` returns False, the word **definitely** does not exist
→ skip all disk I/O immediately.
"""

from __future__ import annotations

import hashlib
import math
from engine.config import BLOOM_SIZE, BLOOM_HASH_COUNT


class BloomFilter:
    """Bit-array Bloom filter with configurable size and hash count."""

    def __init__(self, size: int = BLOOM_SIZE, hash_count: int = BLOOM_HASH_COUNT) -> None:
        self.size = size
        self.hash_count = hash_count
        self._bits = bytearray(math.ceil(size / 8))

    # ── Add ───────────────────────────────────────────────────────────

    def add(self, item: str) -> None:
        """Insert *item* into the filter."""
        for idx in self._hashes(item):
            byte_idx, bit_idx = divmod(idx, 8)
            self._bits[byte_idx] |= (1 << bit_idx)

    # ── Query ─────────────────────────────────────────────────────────

    def might_contain(self, item: str) -> bool:
        """Return False if *item* is **definitely** absent, True if maybe present."""
        for idx in self._hashes(item):
            byte_idx, bit_idx = divmod(idx, 8)
            if not (self._bits[byte_idx] & (1 << bit_idx)):
                return False
        return True

    # ── Bulk ──────────────────────────────────────────────────────────

    def bulk_add(self, items: list[str]) -> None:
        for item in items:
            self.add(item)

    # ── Internals ─────────────────────────────────────────────────────

    def _hashes(self, item: str) -> list[int]:
        """Generate *hash_count* independent hash positions for *item*."""
        positions: list[int] = []
        encoded = item.lower().encode("utf-8")
        for i in range(self.hash_count):
            h = hashlib.md5(encoded + i.to_bytes(1, "big")).hexdigest()
            positions.append(int(h, 16) % self.size)
        return positions

    # ── Serialization (for persistence) ───────────────────────────────

    def to_bytes(self) -> bytes:
        return bytes(self._bits)

    @classmethod
    def from_bytes(cls, data: bytes, size: int = BLOOM_SIZE,
                   hash_count: int = BLOOM_HASH_COUNT) -> "BloomFilter":
        bf = cls(size=size, hash_count=hash_count)
        bf._bits = bytearray(data)
        return bf
