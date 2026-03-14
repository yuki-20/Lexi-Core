# Changelog

All notable changes to LexiCore are documented in this file.

---

## [5.6] — 2026-03-15

### ✨ New Features

- **Level overview endpoint** — `GET /api/xp/levels` returns all 20 milestone levels with XP thresholds, titles, and glow tiers (null/uncommon/rare/epic/legendary) for building a level roadmap UI
- **Batch flashcard creation** — `POST /api/decks/{deck_id}/cards/batch` accepts a list of words and auto-fills definitions from local dictionary, enabling multi-select add from saved words
- **Cambridge Dictionary fallback** — `cambridge.py` fully rewritten with 2-attempt retry logic on dictionaryapi.dev + HTML scraping fallback from Cambridge Dictionary when the API fails

### 🐛 Bug Fixes

- **Digest reliability** — Increased API delay from 0.05s to 0.3s to prevent rate limiting; added `skipped` word counter to final SSE payload so the UI can report exactly how many words failed
- **AI Bearer error** — Guarded both `/api/ai/chat` and `/api/ai/chat/stream` to skip the `Authorization: Bearer` header entirely when the API key is empty or missing, preventing the `Illegal header value b'Bearer '` crash
- **Pet descriptions missing** — Pet descriptions now fallback to auto-generated text (e.g., "A companion unlocked by: Reach 7-day streak") when the `desc` field in `PETS` dictionary is empty
- **Quiz generation error** — Error message now shows exact counts: `"Only X words have definitions (need 4+)"` with `valid_count` and `total_count` fields, helping users understand why quiz can't generate

### 📁 Files Modified

- `engine/media/cambridge.py` — Full rewrite (185 lines): retry logic, Cambridge HTML scraper, async aiohttp session
- `engine/main.py` — 7 targeted changes across digest, AI chat, pets, quiz, and 2 new endpoints

---

## [5.5.1] — 2026-03-13

### 🛠 Fresh Install Recovery

- **Fixed Windows fresh installs** — installer now deletes the full previous app tree, rebuilds a local `.venv`, installs only supported runtime dependencies, and aborts on bootstrap failures instead of leaving a half-installed app behind
- **Bundled Windows UI** — installer now ships with a local `LexiCore_UI.zip` payload instead of downloading the broken `LexiCore_UI.zip` release URL
- **Sample dictionary prebuild** — installer now builds `data/index.data` and `data/meaning.bin` during setup so first launch is immediately usable
- **Safe AI bootstrap** — missing `engine/ai_config.json` no longer crashes startup; AI chat is disabled cleanly with an ASCII-safe warning
- **Runtime dependency fix** — added `python-multipart` for file upload endpoints and moved `vosk` / `PyAudio` out of core install requirements so normal Windows machines can install successfully

### 🐛 Regression Fixes

- **Quiz XP restored** — `POST /api/quiz/submit` now awards quiz XP again after the deadlock fix, including perfect-score bonus
- **Quiz quests restored** — submitting a quiz now advances both `quiz_1` and `master_10` quest progress and grants quest bonus XP when completed
- **Quiz history timestamps fixed** — history rows now expose both `taken_at` and `created_at` for the Flutter history view
- **Daily login XP gated** — `daily_login` can only be claimed once per day on the backend, preventing duplicate XP from repeated launches
- **Profile name sync fixed** — `name` and `display_name` now stay mirrored so Home, Welcome, and Settings show the same user name on a fresh database
- **Dictionary fallback completed** — dictionary expansion now truly follows the documented chain: local binary → search → online → saved words
- **Pet unlock toast fixed** — quiz results now surface newly unlocked pets from the submit response instead of re-checking after they were already unlocked
- **Sidebar progress refresh fixed** — XP, level, and pet state now refresh in the shell when progress changes without requiring a full restart
- **Custom-word quiz validation fixed** — quiz generation from imported/custom words now returns `400` unless at least 4 real definitions were found

### ✨ v6 Backport

- **Achievement badges** — added persistent unlock tracking plus `/api/achievements`, with badge cards now shown on the Performance page

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
