# 🌊 LexiCore Engine v5.4

<div align="center">

**A blazing-fast, offline-first vocabulary learning platform with AI-powered search, flashcards, and a premium Liquid Glass UI.**

[![Python 3.12+](https://img.shields.io/badge/Python-3.12+-blue?logo=python&logoColor=white)](https://python.org)
[![Flutter](https://img.shields.io/badge/Flutter-Desktop-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115+-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![License](https://img.shields.io/badge/License-Apache%202.0-green)](LICENSE)

</div>

---

## ✨ Key Features

### 🔍 Dictionary Engine
- **Exact search** with Huffman-compressed binary index (sub-millisecond lookups on 300K+ words)
- **Fuzzy matching** with Levenshtein + Double Metaphone phonetic algorithms
- **Autocomplete** via in-memory Trie with prefix search
- **Reverse dictionary** using TF-IDF inverted index (find words by definition)
- **Bloom filter** for instant negative lookups
- **Cambridge Dictionary** online fallback for words not in local DB
- **Word of the Day** with 2-hour local rotation or curated online picks

### 🤖 Lexi AI Assistant
- **10 LLM models** via FPT AI Factory (DeepSeek-R1, Qwen3, Gemma 3, Llama 3.3, GLM-4, and more)
- **Real-time streaming** with Server-Sent Events (SSE)
- **Chain-of-Thought (CoT)** — `<think>` tag extraction with collapsible accordion UI
- **Web Search (RAG)** — DuckDuckGo web search with results injected into system prompt
- **Vision support** — Image upload for Gemma 3 27B (multimodal analysis)
- **Conversation history** — Save, resume, and manage chat sessions
- **Encrypted API key** — Fernet + PBKDF2 encryption with admin-only decryption

### 📚 Flashcard System
- **Create decks** manually or auto-generate from word lists
- **Full deck editor** — Add, edit, rename, and delete cards with inline editing
- **3D flip cards** with spring animations for study mode
- **SM-2 spaced repetition** mastery tracking per card
- **Auto-definitions** — Cards auto-fill definitions from the dictionary

### 📝 Quiz System
- **Multiple-choice quizzes** generated from saved words or flashcard decks
- **Instant grading** with detailed feedback and score tracking
- **Quiz history** with review and analytics

### 📊 Learning Analytics
- **Performance dashboard** with daily activity charts
- **XP & Leveling** — Earn XP for searches, saves, quizzes, and more
- **Daily quests** — Complete challenges for bonus XP
- **Streak system** with day-count tracking
- **Streak Pets** — Unlock virtual companions (Ember Fox, Volt Owl, Aqua Dragon, Prisma) at milestone streaks

### 📁 Projects & Organization
- **Project folders** — Group vocabulary by topic, class, or goal
- **Color-coded** with custom icons
- **Per-project decks** — Create focused flashcard sets within projects

### 🎧 Multimedia
- **Pronunciation audio** (TTS via gTTS, Cambridge audio URLs)
- **Contextual images** for visual vocabulary learning
- **OCR screen capture** — Grab text from screen regions
- **Anki export** — Export decks as `.apkg` files for Anki
- **File import** — Bulk import words from `.txt` or `.json` files

### 🎨 Liquid Glass UI
- **iOS 26-inspired** glassmorphism with GPU-accelerated CustomPainters
- **Animated sidebar** with responsive LayoutBuilder
- **Smooth micro-animations** via `flutter_animate`
- **Dark theme** with curated teal/purple/pink accent palette
- **Custom water drop app icon** with transparency

---

## 🏗️ Architecture

```
LexiCore v5.4
├── engine/                     Python Backend (FastAPI on :8741)
│   ├── data/                   Huffman coding, binary index, meaning store
│   │   ├── huffman.py          Huffman compression/decompression
│   │   ├── index_store.py      Binary index file reader
│   │   └── meaning_store.py    Meaning binary file reader
│   ├── search/                 Search algorithms
│   │   ├── trie.py             Trie for autocomplete
│   │   ├── bloom.py            Bloom filter for fast negative lookups
│   │   ├── fuzzy.py            Levenshtein + Metaphone fuzzy matching
│   │   └── cache.py            LRU cache for hot lookups
│   ├── learning/               Learning engine
│   │   ├── db.py               SQLite (SM-2, flashcards, quizzes, profiles)
│   │   ├── sm2.py              SM-2 spaced repetition algorithm
│   │   └── xp_engine.py        XP, leveling, and daily quests
│   ├── media/                  Multimedia services
│   │   ├── tts.py              Text-to-speech audio
│   │   ├── images.py           Contextual image fetching
│   │   ├── ocr.py              Screen region OCR
│   │   ├── anki_export.py      Anki .apkg export
│   │   └── cambridge.py        Cambridge Dictionary scraper
│   ├── main.py                 FastAPI server (1400+ lines, 60+ endpoints)
│   ├── ai_config.json          Encrypted API key (gitignored)
│   └── encrypt_key.py          API key encryption utility
│
├── ui/                         Flutter Desktop Frontend
│   ├── lib/
│   │   ├── main.dart           App shell, animated sidebar, routing
│   │   ├── pages/
│   │   │   ├── home_page.dart          Dashboard, Word of the Day, streaks
│   │   │   ├── lexi_ai_page.dart       AI chat with CoT, web search, vision
│   │   │   ├── flashcards_page.dart    Deck editor, 3D flip study mode
│   │   │   ├── quiz_page.dart          Quiz interface
│   │   │   ├── projects_page.dart      Project management
│   │   │   ├── project_detail_page.dart  Project details + decks
│   │   │   ├── saved_words_page.dart   Saved vocabulary list
│   │   │   ├── performance_page.dart   Analytics dashboard
│   │   │   └── settings_page.dart      User profile, avatar, preferences
│   │   ├── services/
│   │   │   └── engine_service.dart     HTTP/SSE client for all API calls
│   │   ├── theme/
│   │   │   └── liquid_glass_theme.dart Design tokens, colors, typography
│   │   └── widgets/
│   │       └── glass_panel.dart        Reusable glassmorphism container
│   └── assets/images/                  App icons, brand assets
│
├── data/                       Generated data files (gitignored)
│   ├── index.data              Binary word index
│   ├── meaning.bin             Huffman-compressed definitions
│   └── user_progress.db        SQLite user database
│
└── scripts/
    └── sample_dictionary.json  Source dictionary for building index
```

---

## 🚀 Quick Start

### Prerequisites
- **Python 3.12+** with pip
- **Flutter 3.x** (Windows desktop enabled)
- **FPT AI Factory API key** (for Lexi AI features)

### Backend Setup

```bash
# Clone the repository
git clone https://github.com/yuki-20/Lexi-Core.git
cd Lexi-Core

# Install Python dependencies
pip install -r requirements.txt

# Build the dictionary from source JSON
python -m engine.data.builder scripts/sample_dictionary.json

# (Optional) Encrypt your FPT AI API key
python -m engine.encrypt_key

# Start the API server
python -m engine.main
# Server runs on http://localhost:8741
```

### Frontend Setup

```bash
cd ui

# Get Flutter dependencies
flutter pub get

# Run on Windows
flutter run -d windows
```

### Environment Variables

| Variable | Description | Default |
|---|---|---|
| `LEXI_ADMIN_KEY` | Password for API key decryption | `LexiAdmin2026` |
| `LEXI_PORT` | Backend server port | `8741` |

---

## 📡 API Reference

All endpoints are available at `http://localhost:8741`.

### Dictionary & Search

| Endpoint | Method | Description |
|---|---|---|
| `/api/search?q=` | GET | Exact word lookup with full definition |
| `/api/fuzzy?q=` | GET | Fuzzy + phonetic matching |
| `/api/autocomplete?prefix=` | GET | Trie-based typeahead (up to 50) |
| `/api/reverse?q=` | GET | Reverse dictionary via TF-IDF |
| `/api/search/online?q=` | GET | Cambridge Dictionary fallback |
| `/api/pronounce?q=` | GET | Pronunciation audio URL (US/UK) |
| `/api/audio?q=` | GET | Fetch TTS audio |
| `/api/image?q=` | GET | Contextual vocabulary image |
| `/api/ocr` | POST | OCR screen region capture |
| `/api/wotd` | GET | Word of the Day |
| `/ws` | WebSocket | Real-time autocomplete stream |

### Learning & Progress

| Endpoint | Method | Description |
|---|---|---|
| `/api/review` | POST | Submit SM-2 review grade |
| `/api/reviews/due` | GET | Get due review cards |
| `/api/stats` | GET | Engine & learning statistics |
| `/api/saved` | GET/POST/DELETE | Manage saved word list |
| `/api/history` | GET | Lookup history |
| `/api/profile` | GET/PUT | User profile management |
| `/api/avatar` | GET/POST | Avatar upload/retrieve |
| `/api/xp/status` | GET | XP, level, and progress |
| `/api/xp/award` | POST | Award XP for actions |
| `/api/quests` | GET | Daily quest progress |
| `/api/welcome` | GET | Personalized welcome message |

### Flashcard Decks

| Endpoint | Method | Description |
|---|---|---|
| `/api/decks` | GET | List all decks |
| `/api/decks` | POST | Create a new deck |
| `/api/decks/{id}` | PUT | Rename a deck |
| `/api/decks/{id}` | DELETE | Delete a deck |
| `/api/decks/{id}/cards` | GET | List cards in a deck |
| `/api/decks/{id}/cards` | POST | Add a card (auto-fills definition) |
| `/api/decks/{id}/cards/{cid}` | PUT | Update card word/definition |
| `/api/cards/{id}` | DELETE | Delete a card |
| `/api/decks/from-words` | POST | Bulk create deck from word list |

### Quiz System

| Endpoint | Method | Description |
|---|---|---|
| `/api/quiz/generate` | GET | Generate multiple-choice quiz |
| `/api/quiz/submit` | POST | Submit answers & get grading |
| `/api/quiz/history` | GET | Quiz attempt history |
| `/api/quiz/{id}` | GET | Quiz detail by ID |

### AI Chat (Lexi AI)

| Endpoint | Method | Description |
|---|---|---|
| `/api/ai/chat` | POST | Non-streaming chat with CoT extraction |
| `/api/ai/chat/stream` | POST | SSE streaming with real-time thinking + answer |
| `/api/ai/history` | GET | List conversation history |
| `/api/ai/history/{id}` | GET | Get conversation detail |
| `/api/ai/save` | POST | Save conversation |
| `/api/ai/history/{id}` | DELETE | Delete conversation |

**AI Chat Request Body:**
```json
{
  "messages": [{"role": "user", "content": "What is etymology?"}],
  "model": "DeepSeek-R1",
  "web_search": true,
  "images": ["data:image/jpeg;base64,..."]
}
```

### Projects

| Endpoint | Method | Description |
|---|---|---|
| `/api/projects` | GET/POST | List/create projects |
| `/api/projects/{id}` | GET/PUT/DELETE | Project CRUD |
| `/api/projects/{id}/decks` | POST | Create deck within project |

### File Import & Export

| Endpoint | Method | Description |
|---|---|---|
| `/api/import` | POST | Import words from .txt/.json file |
| `/api/import/files` | GET | List imported files |
| `/api/import/files/{id}` | DELETE | Delete imported file |
| `/api/import/files/{id}/words` | GET | Get words from imported file |
| `/api/export` | POST | Export to Anki .apkg |

### Streak Pets & Performance

| Endpoint | Method | Description |
|---|---|---|
| `/api/pets` | GET | All pets with unlock status |
| `/api/pets/unlocked` | GET | User's unlocked pets |
| `/api/pets/check` | POST | Check & unlock new pets |
| `/api/performance` | GET | Current performance stats |
| `/api/performance/history` | GET | Daily performance over time |

---

## 🤖 Supported AI Models

| Model | Provider | Capabilities |
|---|---|---|
| **DeepSeek-R1** | DeepSeek | Reasoning, CoT, general |
| **DeepSeek-V3.2-Speciale** | DeepSeek | Fast, general purpose |
| **Qwen3-32B** | Alibaba | Multilingual, reasoning |
| **Qwen2.5-Coder-32B** | Alibaba | Code generation |
| **Llama-3.3-70B** | Meta | General, instruction-following |
| **Gemma 3 27B** | Google | **Vision** (image + text), reasoning |
| **GLM-4.5** | Z.ai | Reasoning, agentic |
| **GLM-4.7** | Z.ai | Coding, reasoning |
| **GPT-OSS-120B** | Community | Large-scale general |
| **GPT-OSS-20B** | Community | Lightweight general |

> 📷 **Vision support**: Gemma 3 27B accepts image uploads for visual analysis.

---

## 🗺️ Development Roadmap

### ✅ Completed (v1.0 → v5.4)

| Version | Features |
|---|---|
| **v1.0** | Core dictionary engine, Huffman compression, Trie, Bloom filter |
| **v2.0** | FastAPI server, fuzzy search, TTS, OCR, Anki export, SM-2 learning |
| **v3.0** | Flashcards, quizzes, file import, user profiles, streak pets, performance analytics, projects, XP/leveling system |
| **v3.1** | Avatar upload, project folders, daily quests |
| **v4.0** | Flutter Liquid Glass UI, animated sidebar, dark theme, 9-page app |
| **v5.0** | Lexi AI integration (10 models), CoT extraction, streaming SSE, conversation history |
| **v5.3** | Encrypted API key, custom water drop icon, transparent app icons |
| **v5.4** | Web search (DuckDuckGo RAG), universal CoT, vision model support (Gemma 3), flashcard deck editor (CRUD), `<think>` tag instructions for all models |

### 🔮 Planned (v6.0+)

- [ ] **Spaced repetition scheduler** — Smart review scheduling with due card notifications
- [ ] **Voice input** — Speech-to-text for hands-free vocabulary lookup
- [ ] **Multi-language support** — Japanese, Korean, Spanish dictionary packs
- [ ] **Collaborative decks** — Share flashcard decks with other users
- [ ] **AI-generated quizzes** — LLM-powered adaptive quiz generation
- [ ] **Mobile support** — Flutter Android/iOS builds
- [ ] **Offline AI** — On-device LLM for basic dictionary queries
- [ ] **Plugin system** — Extensible engine modules for custom data sources
- [ ] **Theme editor** — User-customizable UI themes and accent colors
- [ ] **Cloud sync** — Cross-device progress synchronization

---

## 🧪 Testing

```bash
# Run all backend tests
python -m pytest engine/tests/ -v

# Run with coverage
python -m pytest engine/tests/ --cov=engine --cov-report=html
```

---

## 📦 Tech Stack

| Layer | Technology |
|---|---|
| **Backend** | Python 3.12+, FastAPI, Uvicorn, httpx |
| **Frontend** | Flutter 3.x (Windows Desktop) |
| **Database** | SQLite (via Python sqlite3) |
| **AI** | FPT AI Factory API (10 LLMs) |
| **Web Search** | DuckDuckGo HTML API |
| **Data Structures** | Huffman tree, Trie, Bloom filter, TF-IDF inverted index |
| **Algorithms** | SM-2 spaced repetition, Levenshtein distance, Double Metaphone |
| **Encryption** | Fernet (AES-128-CBC) + PBKDF2-SHA256 |
| **Audio** | gTTS, Cambridge pronunciation URLs |
| **Image** | Pillow, Tesseract OCR |

---

## 📄 License

[Apache License 2.0](LICENSE)

---

<div align="center">

**Built with ❤️ by [yuki-20](https://github.com/yuki-20)**

</div>
