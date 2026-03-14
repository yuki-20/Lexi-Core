# 🌊 LexiCore Engine v5.6

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
- **Autocomplete** via in-memory Trie with instant prefix search (triggers on first keystroke)
- **Reverse dictionary** using TF-IDF inverted index (find words by definition)
- **Bloom filter** for instant negative lookups
- **Cambridge Dictionary** online fallback for words not in local DB
- **Word of the Day** with 2-hour local rotation or curated online picks
- **Save to Dictionary** — Push saved words into the dictionary browser with one tap

### 🤖 Lexi AI Assistant
- **10 LLM models** (DeepSeek-R1, Qwen3, Gemma 3, Llama 3.3, GLM-4, and more)
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
- **Multiple-choice quizzes** generated from saved words, flashcard decks, custom words, or imported files
- **Selectable question count** — Choose 5–30 questions per quiz via slider
- **Auto-digest on import** — Words without definitions are automatically looked up before generating quiz
- **Smart definition lookup** — Local dictionary + online API fallback ensures every question has a proper answer
- **Performance analytics** — Time taken, accuracy rate, avg time per question, per-question breakdown
- **Quiz history chart** — Line chart showing score trend over time with best/average/total stats
- **Past quiz records** — Browse recent quizzes with score badges and progress bars

### 📊 Learning Analytics
- **Performance dashboard** with daily activity charts
- **XP & Leveling v2** — Rebalanced polynomial curve (level² × 150), max level 1000
- **20 unique titles** — From "Novice" (Lv 1) → "Word Titan" (Lv 750) → "∞ Eternal Lexicon" (Lv 1000)
- **Title progression** — Every 5 levels for first 30, then every 10 levels, with special milestones
- **Daily quests** — Complete challenges for bonus XP
- **Achievement badges** — Unlock milestone rewards for search, save, streak, quiz, pet, and mastery progress
- **Streak system** with day-count tracking and XP multipliers (1.1× to 1.6×)
- **Streak Pets** — Unlock virtual companions (Ember Fox, Volt Owl, Aqua Dragon, Prisma) at milestone streaks
- **Level roadmap API** — `GET /api/xp/levels` returns all 20 milestones with glow tiers for profile UI

### 📁 Saved Words & Organization
- **Save/unsave toggle** — Tap bookmark to save, tap again to unsave (correctly synced across views)
- **Digested vs Undigested** — Words separated by whether definitions have been fetched
- **Background digest** — Auto-fetch definitions for all undigested words with progress bar
- **Add to Dictionary** — Push all digested saved words into the dictionary browser
- **Create flashcard decks** from saved words with one tap
- **Project folders** — Group vocabulary by topic, class, or goal with color-coding

### 🎧 Multimedia
- **Pronunciation audio** (TTS via gTTS, Cambridge audio URLs) — In-app playback
- **Contextual images** for visual vocabulary learning
- **OCR screen capture** — Grab text from screen regions
- **Anki export** — Export decks as `.apkg` files for Anki
- **File import** — Bulk import words from `.txt` or `.json` files with streaming progress

### 🎨 Liquid Glass UI
- **iOS 26-inspired** glassmorphism with GPU-accelerated CustomPainters
- **Animated sidebar** with responsive LayoutBuilder
- **Smooth micro-animations** via `flutter_animate`
- **Dark theme** with curated teal/purple/pink accent palette
- **Custom water drop app icon** with transparency

---

## 🏗️ Architecture

```
LexiCore v5.6
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
│   │   └── xp_engine.py        XP v2 — level² curve, max 1000, 20 titles
│   ├── media/                  Multimedia services
│   │   ├── tts.py              Text-to-speech audio
│   │   ├── images.py           Contextual image fetching
│   │   ├── ocr.py              Screen region OCR
│   │   ├── anki_export.py      Anki .apkg export
│   │   └── cambridge.py        Cambridge Dictionary + dictionaryapi.dev
│   ├── main.py                 FastAPI server (1900+ lines, 75+ endpoints)
│   ├── ai_config.json          Encrypted API key (gitignored)
│   └── encrypt_key.py          API key encryption utility
│
├── ui/                         Flutter Desktop Frontend
│   ├── lib/
│   │   ├── main.dart           App shell, animated sidebar, routing
│   │   ├── pages/
│   │   │   ├── home_page.dart          Search, save/unsave toggle, Word of the Day
│   │   │   ├── lexi_ai_page.dart       AI chat with CoT, web search, vision
│   │   │   ├── flashcards_page.dart    Deck editor, 3D flip study mode
│   │   │   ├── quiz_page.dart          Quiz with analytics, history chart
│   │   │   ├── dictionary_page.dart    Alphabetical browser with expand-to-define
│   │   │   ├── projects_page.dart      Project management
│   │   │   ├── project_detail_page.dart  Project details + decks
│   │   │   ├── saved_words_page.dart   Saved words, digest, add-to-dictionary
│   │   │   ├── performance_page.dart   Analytics dashboard + achievement badges
│   │   │   └── settings_page.dart      User profile, avatar, preferences
│   │   ├── services/
│   │   │   └── engine_service.dart     HTTP/SSE client for all API calls
│   │   ├── theme/
│   │   │   └── liquid_glass_theme.dart Design tokens, colors, typography
│   │   └── widgets/
│   │       ├── glass_panel.dart        Reusable glassmorphism container
│   │       ├── definition_card.dart    Word definition + audio + save toggle
│   │       └── search_bar.dart         Pill-shaped glass search input
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
- **Lexi AI**

### Backend Setup

```bash
# Clone the repository
git clone https://github.com/yuki-20/Lexi-Core.git
cd Lexi-Core

# Install runtime dependencies
pip install -r requirements.txt

# Build the dictionary from source JSON
python -m engine.data.builder scripts/sample_dictionary.json

# (Optional) Encrypt your FPT AI API key
python -m engine.encrypt_key

# Start the API server
python -m engine.main
# Server runs on http://localhost:8741
```

Optional speech input dependencies:

```bash
pip install .[speech]
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

### Dictionary Browser

| Endpoint | Method | Description |
|---|---|---|
| `/api/dictionary/words` | GET | Paginated word list (letter filter, pagination) |
| `/api/dictionary/letters` | GET | Available letters with word counts |
| `/api/dictionary/add-saved` | POST | Merge saved words into dictionary |

### Learning & Progress

| Endpoint | Method | Description |
|---|---|---|
| `/api/review` | POST | Submit SM-2 review grade |
| `/api/reviews/due` | GET | Get due review cards |
| `/api/stats` | GET | Engine & learning statistics |
| `/api/saved` | GET/POST/DELETE | Manage saved word list |
| `/api/saved/digest` | POST | Auto-fetch definitions for undigested words |
| `/api/history` | GET | Lookup history |
| `/api/profile` | GET/PUT | User profile management |
| `/api/avatar` | GET/POST | Avatar upload/retrieve |
| `/api/xp/status` | GET | XP, level, title, and progress |
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
| `/api/quiz/generate` | GET | Generate quiz from saved words (auto-digests) |
| `/api/quiz/generate` | POST | Generate quiz from custom word list |
| `/api/quiz/submit` | POST | Submit answers, save result, get grading |
| `/api/quiz/history` | GET | Quiz attempt history with scores |
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
| `/api/import/file/stream` | POST | Streaming import with SSE progress |
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

## ⚡ XP & Leveling System (v2)

| Level | Title | XP Required |
|---|---|---|
| 1 | Novice | 0 |
| 5 | Word Sprout | 3,750 |
| 10 | Curious Learner | 15,000 |
| 15 | Word Explorer | 33,750 |
| 20 | Rising Wordsmith | 60,000 |
| 25 | Skilled Linguist | 93,750 |
| 30 | Word Connoisseur | 135,000 |
| 50 | Vocabulary Artisan | 375,000 |
| 100 | Vocabulary Master | 1,500,000 |
| 200 | Eloquence Lord | 6,000,000 |
| 500 | Grand Lexicographer | 37,500,000 |
| 750 | Word Titan | 84,375,000 |
| 1000 | ∞ Eternal Lexicon | 150,000,000 |

**XP Awards:** Search (+3), Save (+5), Quiz Correct (+10), Quiz Perfect (+50), Daily Login (+10), Flashcard (+5), Deck Complete (+25)

**Streak Multipliers:** 2+ days (1.1×), 7+ days (1.25×), 14+ days (1.4×), 30+ days (1.6×)

---

## 🗺️ Development Roadmap

### ✅ Completed (v1.0 → v5.5)

| Version | Features |
|---|---|
| **v1.0** | Core dictionary engine, Huffman compression, Trie, Bloom filter |
| **v2.0** | FastAPI server, fuzzy search, TTS, OCR, Anki export, SM-2 learning |
| **v3.0** | Flashcards, quizzes, file import, user profiles, streak pets, performance analytics, projects, XP/leveling |
| **v3.1** | Avatar upload, project folders, daily quests |
| **v4.0** | Flutter Liquid Glass UI, animated sidebar, dark theme, 9-page app |
| **v5.0** | Lexi AI integration (10 models), CoT extraction, streaming SSE, conversation history |
| **v5.3** | Encrypted API key, custom water drop app icon, transparent app icons |
| **v5.4** | Web search (DuckDuckGo RAG), universal CoT, vision (Gemma 3), flashcard deck editor, `<think>` tags |
| **v5.5** | Quiz analytics & history chart, save/unsave toggle, add-to-dictionary, XP v2 rebalance (max 1000, 20 titles), auto-digest, quiz count selector, definition quality fixes, SQLite deadlock fix |
| **v5.5.1** | Fresh install recovery (venv isolation, bundled UI, sample dictionary prebuild), safe AI bootstrap (missing key no longer crashes), runtime dependency fix (python-multipart added, PyAudio/vosk moved to optional), quiz XP/quest regression fix, achievement badges backport, daily login XP gating, profile name sync |

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
- [ ] **Leaderboard** — Compare XP and streaks with friends
- [ ] **Word games** — Crossword, word scramble, and hangman mini-games

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
| **Database** | SQLite (WAL mode, 30s busy timeout) |
| **AI** | (10 LLMs) |
| **Web Search** | DuckDuckGo HTML API |
| **Definitions** | dictionaryapi.dev (online fallback) |
| **Data Structures** | Huffman tree, Trie, Bloom filter, TF-IDF inverted index |
| **Algorithms** | SM-2 spaced repetition, Levenshtein distance, Double Metaphone |
| **Encryption** | Fernet (AES-128-CBC) + PBKDF2-SHA256 |
| **Audio** | gTTS, Cambridge pronunciation URLs, audioplayers |
| **Image** | Pillow, Tesseract OCR |

---

## 📄 License

[Apache License 2.0](LICENSE)

---

<div align="center">

**Built with ❤️ by [yuki-20](https://github.com/yuki-20)**

</div>
