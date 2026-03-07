"""Tests for the Bloom Filter."""

from engine.search.bloom import BloomFilter


def test_definitely_absent():
    bf = BloomFilter(size=1024, hash_count=5)
    bf.add("hello")
    bf.add("world")

    assert bf.might_contain("hello") is True
    assert bf.might_contain("world") is True
    # A word never added should (almost certainly) return False
    assert bf.might_contain("xyzzy_unlikely_word") is False


def test_no_false_negatives():
    bf = BloomFilter(size=1 << 16, hash_count=7)
    words = [f"word_{i}" for i in range(500)]
    bf.bulk_add(words)

    for w in words:
        assert bf.might_contain(w) is True, f"False negative for {w}"


def test_serialization():
    bf = BloomFilter(size=256, hash_count=3)
    bf.add("test")
    bf.add("data")

    raw = bf.to_bytes()
    bf2 = BloomFilter.from_bytes(raw, size=256, hash_count=3)

    assert bf2.might_contain("test") is True
    assert bf2.might_contain("data") is True
    assert bf2.might_contain("missing") is False
