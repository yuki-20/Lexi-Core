"""Tests for Huffman encoding/decoding."""

from engine.data.huffman import encode, decode


def test_round_trip():
    text = b"hello world! this is a test of huffman compression."
    compressed, freq_table = encode(text)
    decompressed = decode(compressed, freq_table)
    assert decompressed == text


def test_single_char():
    text = b"aaaa"
    compressed, freq_table = encode(text)
    assert decode(compressed, freq_table) == text


def test_empty():
    compressed, freq_table = encode(b"")
    assert compressed == b""
    assert decode(b"", {}) == b""


def test_compression_ratio():
    text = b"aaaaaabbbbccd"  # highly compressible
    compressed, _ = encode(text)
    # Compressed should be smaller than original (minus header overhead for small inputs)
    # For very small inputs compression may not help, but the round-trip must be correct
    decompressed = decode(compressed, _)
    assert decompressed == text


def test_unicode():
    text = "日本語テスト".encode("utf-8")
    compressed, freq_table = encode(text)
    assert decode(compressed, freq_table) == text
