# Changelog

All notable changes to LexiCore are documented in this file.

---

## [5.5] — 2026-03-09

### ✨ New Features

#### Quiz System Overhaul
- **Quiz question count selector** — Slider to choose 5–30 questions per quiz
- **Quiz performance analytics** — Post-quiz screen shows time taken, accuracy rate, average time per question, and per-question breakdown with correct/incorrect indicators
- **Quiz history chart** — Line chart (CustomPainter) showing score trend over time with gradient fill and data points
- **Quiz history stats** — Best score, total quizzes taken, and overall average displayed in stat cards
- **Recent quizzes list** — Browse past quiz results with score badges, progress bars, and timestamps
- **Auto-digest on import** — When importing words into a quiz (file or custom), undigested words are automatically looked up via dictionaryapi.dev before generating questions

#### Save/Unsave Toggle
- **Bookmark toggle** — Save button now toggles between save and unsave (was one-way before)
- **Saved state sync** — When searching a word that's already saved, the bookmark correctly shows as filled
- **Delete integration** — Uses existing `DELETE /api/saved/{word}` endpoint for unsaving

#### Dictionary Integration
- **Add to Dictionary button** — New 📖 "Dict" button in Saved Words header pushes all digested saved words into the Dictionary browser
- **Backend merge endpoint** — `POST /api/dictionary/add-saved` merges saved words into `engine._all_words` in-memory list
- **Definition fallback chain** — Dictionary word expansion now tries: local binary → full search (incl. online) → saved words SQLite

#### XP & Leveling v2 (Rebalanced)
- **New level formula** — Changed from `100 × level^1.5` to `150 × level^2.0` (much slower progression)
- **Max level 1000** — Previously uncapped, now capped at level 1000
- **20 unique titles** — From "Novice" (Lv 1) to "∞ Eternal Lexicon" (Lv 1000)
- **Title milestones** — Every 5 levels for first 30, then every 10, with special titles at 150, 200, 300, 500, 750, 1000
- **Reduced XP awards** — Search: 5→3, Save: 10→5, Quiz Correct: 25→10, Quiz Perfect: 100→50, Daily Login: 15→10, Flashcard: 10→5, Deck Complete: 50→25
- **Reduced streak multipliers** — Max multiplier reduced from 2.0× to 1.6×

#### Search Improvements
- **Instant autocomplete** — Suggestions now trigger on the very first keystroke (was 2+ characters)

### 🐛 Bug Fixes

#### Quiz Definition Quality
- **Empty definitions fixed** — `generate_quiz()` now filters out words with empty/null definitions before creating quiz questions
- **Online fallback for GET quiz** — `GET /api/quiz/generate` auto-digests words without definitions via `lookup_online()`, saving results for future use
- **Wrong answer validation** — Each question now requires exactly 3 wrong answers; questions without enough options are skipped

#### Quiz History Not Saving
- **SQLite deadlock fixed** — `create_quiz_result()` was calling `self.add_exp()` which opened a second database connection while the first hadn't committed, causing `sqlite3.OperationalError: database is locked`
- **Fix: Inlined SQL** — The `add_exp` SQL is now executed on the same cursor/connection as the quiz result insert
- **Safety net** — Added `timeout=30` to `sqlite3.connect()` and `PRAGMA busy_timeout=30000` to prevent future locking issues

#### Dictionary Crash
- **list.add() → list.append()** — `_all_words` is a list, not a set; `.add()` method doesn't exist on lists, causing 500 error on the add-saved endpoint

#### Dictionary Definitions
- **Saved word definitions** — Dictionary expand now falls back to saved words SQLite when binary dictionary lookup returns null

---

### 📁 Files Modified

#### Backend (`engine/`)
| File | Changes |
|---|---|
| `main.py` | Added `POST /api/dictionary/add-saved`, fixed `GET /api/quiz/generate` with online lookup fallback, fixed `POST /api/quiz/generate` definition handling |
| `learning/db.py` | Fixed `generate_quiz()` to filter empty definitions, fixed `create_quiz_result()` deadlock by inlining `add_exp` SQL, added `timeout=30` and `busy_timeout=30000` to SQLite connection |
| `learning/xp_engine.py` | Complete rewrite — level^2.0 formula, max level 1000, 20 titles, halved XP awards, reduced streak multipliers |

#### Frontend (`ui/lib/`)
| File | Changes |
|---|---|
| `pages/home_page.dart` | Replaced `_onSaveWord` with `_onToggleSave` (save/unsave toggle), added saved state check on search, autocomplete threshold 2→1 |
| `pages/quiz_page.dart` | New `_buildResult()` with analytics (time, accuracy, breakdown), new `_buildHistory()` with chart, `_StatCard` widget, `_QuizChartPainter` (CustomPainter), added `'history'` state |
| `pages/saved_words_page.dart` | Added `_addToDictionary()` method and 📖 Dict button in header |
| `pages/dictionary_page.dart` | Updated `_expandWord()` with 3-tier fallback: binary → search → saved words |
| `services/engine_service.dart` | Added `addSavedToDictionary()` method |

---

## [5.4] — 2026-03-07

- Web search (DuckDuckGo RAG) for AI chat
- Universal CoT extraction for all models
- Vision model support (Gemma 3 27B)
- Flashcard deck editor with full CRUD
- `<think>` tag instructions injected for all models
- Custom system prompt in settings

## [5.3] — 2026-03-06

- Encrypted API key storage (Fernet + PBKDF2)
- Custom water drop app icon with transparency
- Transparent app icon for Windows

## [5.0] — 2026-03-04

- Lexi AI integration with 10 LLM models
- Chain-of-Thought extraction with collapsible UI
- Real-time SSE streaming
- Conversation history management

## [4.0] — 2026-03-01

- Flutter Liquid Glass UI (iOS 26 inspired)
- Animated sidebar with responsive layout
- Dark theme with teal/purple/pink palette
- 9-page desktop application

## [3.0–3.1] — 2026-02-26

- Flashcard system with SM-2 spaced repetition
- Quiz system with multiple-choice
- File import (.txt/.json)
- User profiles and avatars
- Streak pets and performance analytics
- Project folders with color coding
- XP/leveling system and daily quests

## [2.0] — 2026-02-20

- FastAPI REST server
- Fuzzy search with phonetic matching
- TTS pronunciation audio
- OCR screen capture
- Anki .apkg export

## [1.0] — 2026-02-15

- Core dictionary engine
- Huffman-compressed binary index
- Trie autocomplete
- Bloom filter for fast negative lookups
- TF-IDF inverted index for reverse search
