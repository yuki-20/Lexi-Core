# LexiCore Engine v2.0 Ultimate

A blazing-fast, offline dictionary and multimedia vocabulary engine.

## Architecture

```
Python Backend (engine/)          React/Tauri Frontend (ui/)
  ├─ data/     (Huffman, Index)     ├─ Liquid Glass UI
  ├─ search/   (Trie, Bloom, LRU)  ├─ Spring animations
  ├─ learning/ (SM-2, Streaks)     └─ Framer Motion
  ├─ media/    (TTS, OCR, Images)
  └─ main.py   (FastAPI on :8741)
       │
       └── WebSocket / HTTP ──────────► Frontend
```

## Quick Start

```bash
# Install dependencies
pip install -r requirements.txt

# Build dictionary from source JSON
python -m engine.data.builder scripts/sample_dictionary.json

# Start the API server
python -m engine.main

# Run tests
python -m pytest engine/tests/ -v
```

## API Endpoints

| Endpoint | Method | Description |
|---|---|---|
| `/api/search?q=` | GET | Exact word lookup |
| `/api/fuzzy?q=` | GET | Fuzzy + phonetic matching |
| `/api/autocomplete?prefix=` | GET | Trie-based typeahead |
| `/api/reverse?q=` | GET | Reverse dictionary (TF-IDF) |
| `/api/audio?q=` | GET | Pronunciation MP3 |
| `/api/image?q=` | GET | Contextual image |
| `/api/ocr` | POST | OCR screen grab |
| `/api/export` | POST | Anki .apkg export |
| `/api/review` | POST | SM-2 spaced repetition |
| `/api/wotd` | GET | Word of the Day |
| `/api/stats` | GET | Engine & learning stats |
| `/ws` | WebSocket | Real-time autocomplete |

## Tech Stack

- **Backend**: Python 3.12+, FastAPI, Huffman coding, Trie, Bloom filter, SM-2
- **Frontend**: React 18+, Tauri, Framer Motion, Liquid Glass UI
- **Storage**: Custom binary files (`index.data`, `meaning.bin`) + SQLite

## License

Apache-2.0
