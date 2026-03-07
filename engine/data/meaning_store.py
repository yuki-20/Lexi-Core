"""
LexiCore — Meaning Store (Huffman-compressed definitions)
=========================================================
Manages ``meaning.bin``, a chunked binary file storing dictionary definitions.
Each entry is a Huffman-compressed JSON blob containing:
  { "pos": [...], "synonyms": [...], "examples": [...], "etymology": "..." }
"""

from __future__ import annotations

import json
import struct
from pathlib import Path
from typing import Any

from engine.config import MEANING_PATH
from engine.data.huffman import encode as huff_encode, decode as huff_decode


# ── Serialization Format ──────────────────────────────────────────────
#
# Per-entry layout in meaning.bin:
#   [freq_table_len : 4B uint32]
#   [freq_table     : variable (JSON-encoded bytes)]
#   [compressed     : variable (Huffman payload incl. 4B header)]
#
# The global builder writes entries sequentially; the reader uses the
# byte_offset + bit_length from index.data to locate and read them.
# (bit_length in the index is actually the TOTAL byte-length of the
#  serialized entry for simplicity — renamed conceptually.)


class MeaningStore:
    """Read/write compressed definition entries in meaning.bin."""

    def __init__(self, path: Path | None = None) -> None:
        self.path = path or MEANING_PATH

    # ── Write ─────────────────────────────────────────────────────────

    def open_writer(self) -> "_MeaningWriter":
        """Return a context-manager writer for building meaning.bin."""
        return _MeaningWriter(self.path)

    # ── Read ──────────────────────────────────────────────────────────

    def read_entry(self, byte_offset: int, entry_length: int) -> dict[str, Any]:
        """Read and decompress a single definition entry.

        Parameters
        ----------
        byte_offset : int
            Start position in meaning.bin (from index.data).
        entry_length : int
            Total byte length of the serialized entry.
        """
        with open(self.path, "rb") as f:
            f.seek(byte_offset)
            raw = f.read(entry_length)

        # Parse freq table
        ft_len = struct.unpack(">I", raw[:4])[0]
        ft_json = raw[4:4 + ft_len]
        freq_table: dict[int, int] = {int(k): v for k, v in json.loads(ft_json).items()}

        # Decompress payload
        compressed = raw[4 + ft_len:]
        decompressed = huff_decode(compressed, freq_table)

        return json.loads(decompressed.decode("utf-8"))


class _MeaningWriter:
    """Sequential writer — used during dictionary build."""

    def __init__(self, path: Path) -> None:
        self.path = path
        self._file = None

    def __enter__(self):
        self._file = open(self.path, "wb")
        return self

    def __exit__(self, *exc):
        if self._file:
            self._file.close()

    def write_entry(self, definition: dict[str, Any]) -> tuple[int, int]:
        """Compress and append *definition* to the file.

        Returns (byte_offset, entry_length) for the index.
        """
        assert self._file is not None, "Use as context manager"

        text = json.dumps(definition, ensure_ascii=False).encode("utf-8")
        compressed, freq_table = huff_encode(text)

        ft_json = json.dumps({str(k): v for k, v in freq_table.items()}).encode("utf-8")
        ft_len_bytes = struct.pack(">I", len(ft_json))

        offset = self._file.tell()
        self._file.write(ft_len_bytes)
        self._file.write(ft_json)
        self._file.write(compressed)

        entry_length = len(ft_len_bytes) + len(ft_json) + len(compressed)
        return offset, entry_length
