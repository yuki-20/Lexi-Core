"""
LexiCore — Huffman Coding Engine
================================
Provides lossless compression/decompression of definition text.
Used by meaning_store.py to pack definitions into meaning.bin.
"""

from __future__ import annotations

import heapq
import struct
from collections import Counter
from dataclasses import dataclass, field
from typing import Optional


# ── Huffman Tree Node ─────────────────────────────────────────────────

@dataclass(order=True)
class _HuffNode:
    """Priority-queue-friendly Huffman tree node."""
    freq: int
    char: Optional[int] = field(default=None, compare=False)
    left: Optional["_HuffNode"] = field(default=None, compare=False)
    right: Optional["_HuffNode"] = field(default=None, compare=False)


# ── Public API ────────────────────────────────────────────────────────

def build_frequency_table(data: bytes) -> dict[int, int]:
    """Count byte frequencies in *data*."""
    return dict(Counter(data))


def build_tree(freq_table: dict[int, int]) -> Optional[_HuffNode]:
    """Build a Huffman tree from a frequency table.  Returns the root."""
    if not freq_table:
        return None

    heap: list[_HuffNode] = [_HuffNode(freq=f, char=ch) for ch, f in freq_table.items()]
    heapq.heapify(heap)

    while len(heap) > 1:
        left = heapq.heappop(heap)
        right = heapq.heappop(heap)
        merged = _HuffNode(freq=left.freq + right.freq, left=left, right=right)
        heapq.heappush(heap, merged)

    return heap[0] if heap else None


def _build_codebook(node: Optional[_HuffNode], prefix: str = "",
                    table: dict[int, str] | None = None) -> dict[int, str]:
    """Recursively walk the tree to produce {byte_value: bit_string}."""
    if table is None:
        table = {}
    if node is None:
        return table
    if node.char is not None:
        table[node.char] = prefix or "0"  # single-symbol edge case
        return table
    _build_codebook(node.left, prefix + "0", table)
    _build_codebook(node.right, prefix + "1", table)
    return table


# ── Encode ────────────────────────────────────────────────────────────

def encode(data: bytes) -> tuple[bytes, dict[int, int]]:
    """Compress *data* using Huffman coding.

    Returns
    -------
    compressed : bytes
        Header: 4-byte uint32 = original bit count, then packed bits.
    freq_table : dict[int, int]
        Frequency table needed for decoding.
    """
    if not data:
        return b"", {}

    freq_table = build_frequency_table(data)
    tree = build_tree(freq_table)
    codebook = _build_codebook(tree)

    bit_string = "".join(codebook[b] for b in data)
    total_bits = len(bit_string)

    # Pad to full bytes
    padding = (8 - total_bits % 8) % 8
    bit_string += "0" * padding

    # Pack header (original bit count) + payload
    payload = int(bit_string, 2).to_bytes(len(bit_string) // 8, byteorder="big")
    header = struct.pack(">I", total_bits)

    return header + payload, freq_table


# ── Decode ────────────────────────────────────────────────────────────

def decode(compressed: bytes, freq_table: dict[int, int]) -> bytes:
    """Decompress Huffman-encoded *compressed* using *freq_table*."""
    if not compressed or not freq_table:
        return b""

    total_bits = struct.unpack(">I", compressed[:4])[0]
    payload = compressed[4:]

    # Reconstruct tree
    tree = build_tree(freq_table)
    if tree is None:
        return b""

    # Convert payload to bit string
    bit_string = bin(int.from_bytes(payload, "big"))[2:].zfill(len(payload) * 8)
    bit_string = bit_string[:total_bits]

    # Single-symbol edge case: tree root IS the only leaf
    if tree.char is not None:
        return bytes([tree.char] * total_bits)

    # Walk the tree
    result: list[int] = []
    node = tree
    for bit in bit_string:
        if node is None:
            break
        node = node.left if bit == "0" else node.right
        if node is not None and node.char is not None:
            result.append(node.char)
            node = tree

    return bytes(result)
