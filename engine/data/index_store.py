"""
LexiCore — Fixed-Width Index Store
===================================
Manages ``index.data``, an alphabetically sorted, fixed-width record file.
Each record: [word_key (64 B) | byte_offset (8 B) | bit_length (4 B)] = 76 B.
"""

from __future__ import annotations

import struct
from pathlib import Path
from typing import Iterator

from engine.config import (
    INDEX_PATH,
    WORD_KEY_SIZE,
    OFFSET_SIZE,
    LENGTH_SIZE,
    RECORD_SIZE,
)


# ── Record helpers ────────────────────────────────────────────────────

def _pack_record(word: str, offset: int, bit_length: int) -> bytes:
    """Serialize a single index record to exactly RECORD_SIZE bytes."""
    word_bytes = word.encode("utf-8")[:WORD_KEY_SIZE].ljust(WORD_KEY_SIZE, b"\x00")
    return word_bytes + struct.pack(">Q", offset) + struct.pack(">I", bit_length)


def _unpack_record(raw: bytes) -> tuple[str, int, int]:
    """Deserialize a RECORD_SIZE-byte buffer into (word, offset, bit_length)."""
    word = raw[:WORD_KEY_SIZE].rstrip(b"\x00").decode("utf-8")
    offset = struct.unpack(">Q", raw[WORD_KEY_SIZE:WORD_KEY_SIZE + OFFSET_SIZE])[0]
    bit_length = struct.unpack(">I", raw[WORD_KEY_SIZE + OFFSET_SIZE:])[0]
    return word, offset, bit_length


# ── Public API ────────────────────────────────────────────────────────

class IndexStore:
    """Read/write interface for the fixed-width index file."""

    def __init__(self, path: Path | None = None) -> None:
        self.path = path or INDEX_PATH

    # ── Build ──

    def build(self, entries: list[tuple[str, int, int]]) -> None:
        """Write a sorted list of (word, byte_offset, bit_length) to disk.

        *entries* must be pre-sorted alphabetically by word (case-insensitive).
        """
        with open(self.path, "wb") as f:
            for word, offset, bit_length in entries:
                f.write(_pack_record(word, offset, bit_length))

    # ── Lookup (binary search) ──

    def lookup(self, word: str) -> tuple[int, int] | None:
        """Binary-search the index for *word*.

        Returns (byte_offset, bit_length) or *None* if not found.
        """
        if not self.path.exists():
            return None

        target = word.lower()
        file_size = self.path.stat().st_size
        num_records = file_size // RECORD_SIZE

        with open(self.path, "rb") as f:
            lo, hi = 0, num_records - 1
            while lo <= hi:
                mid = (lo + hi) // 2
                f.seek(mid * RECORD_SIZE)
                rec = f.read(RECORD_SIZE)
                if len(rec) < RECORD_SIZE:
                    break
                w, off, bl = _unpack_record(rec)
                cmp = w.lower()
                if cmp == target:
                    return off, bl
                elif cmp < target:
                    lo = mid + 1
                else:
                    hi = mid - 1

        return None

    # ── Iterate ──

    def iterate(self) -> Iterator[tuple[str, int, int]]:
        """Yield every (word, offset, bit_length) in file order."""
        if not self.path.exists():
            return

        with open(self.path, "rb") as f:
            while True:
                rec = f.read(RECORD_SIZE)
                if len(rec) < RECORD_SIZE:
                    break
                yield _unpack_record(rec)

    # ── Stats ──

    @property
    def count(self) -> int:
        """Number of records in the index."""
        if not self.path.exists():
            return 0
        return self.path.stat().st_size // RECORD_SIZE
