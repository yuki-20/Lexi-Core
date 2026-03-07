"""
LexiCore — Dictionary Builder
==============================
One-shot script: ingests a raw dictionary JSON and produces:
  • data/index.data   (sorted fixed-width index)
  • data/meaning.bin  (Huffman-compressed definitions)

Expected JSON schema (list or dict):
  {
    "word": {
      "pos": ["noun", "verb"],
      "definitions": ["meaning 1", "meaning 2"],
      "synonyms": ["syn1", "syn2"],
      "examples": ["example sentence"],
      "etymology": "origin of the word"
    },
    ...
  }

Or simplified format:
  { "word": "definition string", ... }

Usage:
  python -m engine.data.builder path/to/dictionary.json
"""

from __future__ import annotations

import json
import sys
import time
from pathlib import Path

from engine.config import DATA_DIR
from engine.data.index_store import IndexStore
from engine.data.meaning_store import MeaningStore


def _normalize_entry(word: str, raw: str | dict | list) -> dict:
    """Convert any raw dictionary value into our canonical schema."""
    if isinstance(raw, str):
        return {
            "word": word,
            "pos": [],
            "definitions": [raw],
            "synonyms": [],
            "examples": [],
            "etymology": "",
        }
    if isinstance(raw, list):
        return {
            "word": word,
            "pos": [],
            "definitions": raw,
            "synonyms": [],
            "examples": [],
            "etymology": "",
        }
    # dict — keep what's there, fill gaps
    return {
        "word": word,
        "pos": raw.get("pos", []),
        "definitions": raw.get("definitions", raw.get("meanings", [])),
        "synonyms": raw.get("synonyms", []),
        "examples": raw.get("examples", []),
        "etymology": raw.get("etymology", ""),
    }


def build(source_path: str | Path) -> None:
    """Ingest *source_path* and write index.data + meaning.bin."""
    source = Path(source_path)
    if not source.exists():
        print(f"[ERROR] File not found: {source}")
        sys.exit(1)

    print(f"[*] Loading {source.name} ...")
    with open(source, "r", encoding="utf-8") as f:
        raw_data = json.load(f)

    # Support both dict and list-of-dicts formats
    if isinstance(raw_data, list):
        entries_raw = {}
        for item in raw_data:
            if isinstance(item, dict) and "word" in item:
                entries_raw[item["word"]] = item
    else:
        entries_raw = raw_data

    # Sort words alphabetically
    sorted_words = sorted(entries_raw.keys(), key=str.lower)
    print(f"[*] Processing {len(sorted_words):,} words ...")

    DATA_DIR.mkdir(exist_ok=True)

    index_store = IndexStore()
    meaning_store = MeaningStore()

    index_entries: list[tuple[str, int, int]] = []

    t0 = time.perf_counter()

    with meaning_store.open_writer() as writer:
        for word in sorted_words:
            definition = _normalize_entry(word, entries_raw[word])
            offset, entry_len = writer.write_entry(definition)
            index_entries.append((word, offset, entry_len))

    index_store.build(index_entries)

    elapsed = time.perf_counter() - t0

    print(f"[OK] Built index.data  ({index_store.count:,} records)")
    print(f"[OK] Built meaning.bin ({meaning_store.path.stat().st_size:,} bytes)")
    print(f"[OK] Completed in {elapsed:.2f}s")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python -m engine.data.builder <dictionary.json>")
        sys.exit(1)
    build(sys.argv[1])
