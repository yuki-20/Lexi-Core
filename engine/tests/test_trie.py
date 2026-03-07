"""Tests for the Trie (Prefix Tree)."""

from engine.search.trie import Trie


def test_insert_and_search():
    t = Trie()
    t.insert("hello")
    t.insert("help")
    t.insert("world")

    assert t.search("hello") is True
    assert t.search("help") is True
    assert t.search("world") is True
    assert t.search("hell") is False
    assert t.search("xyz") is False


def test_case_insensitive():
    t = Trie()
    t.insert("Hello")
    assert t.search("hello") is True
    assert t.search("HELLO") is True


def test_autocomplete():
    t = Trie()
    words = ["hello", "help", "hero", "world", "heap"]
    t.bulk_insert(words)

    results = t.autocomplete("he")
    assert "hello" in results
    assert "help" in results
    assert "heap" in results
    assert "hero" in results
    assert "world" not in results


def test_autocomplete_limit():
    t = Trie()
    words = [f"word{i}" for i in range(100)]
    t.bulk_insert(words)

    results = t.autocomplete("word", limit=5)
    assert len(results) == 5


def test_size():
    t = Trie()
    assert t.size == 0
    t.insert("a")
    t.insert("b")
    assert t.size == 2
    t.insert("a")  # duplicate
    assert t.size == 2
