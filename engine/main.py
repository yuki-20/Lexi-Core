"""
LexiCore — FastAPI Main Server (v3.0)
=======================================
The central entrypoint that boots the engine, loads data structures into RAM,
and exposes all API endpoints on localhost:8741.
"""

from __future__ import annotations

import asyncio
import json
import time
from contextlib import asynccontextmanager
from pathlib import Path
from typing import Any

from fastapi import FastAPI, Query, UploadFile, File, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse
from pydantic import BaseModel

from engine.config import (
    API_HOST, API_PORT, DATA_DIR, INDEX_PATH, MEANING_PATH,
    AUTOCOMPLETE_LIMIT, FUZZY_THRESHOLD,
)
from engine.data.index_store import IndexStore
from engine.data.meaning_store import MeaningStore
from engine.search.trie import Trie
from engine.search.bloom import BloomFilter
from engine.search.cache import LRUCache
from engine.search.fuzzy import fuzzy_search
from engine.search.inverted_index import InvertedIndex
from engine.learning.db import UserDB
from engine.learning.sm2 import SM2Scheduler
from engine.learning.streaks import StreakTracker
from engine.learning.wotd import get_word_of_the_day
from engine.media.tts import fetch_audio
from engine.media.images import fetch_image as async_fetch_image
from engine.media.ocr import ocr_screen_region
from engine.media.anki_export import export_to_anki
from engine.media.cambridge import lookup_online, get_pronunciation_url


# ── Engine Singleton ──────────────────────────────────────────────────

class LexiCoreEngine:
    """The god object — holds all data structures in RAM."""

    def __init__(self) -> None:
        self.index_store = IndexStore()
        self.meaning_store = MeaningStore()
        self.trie = Trie()
        self.bloom = BloomFilter()
        self.cache = LRUCache()
        self.inverted_index = InvertedIndex()
        self.db = UserDB()
        self.sm2 = SM2Scheduler(self.db)
        self.streaks = StreakTracker(self.db)
        self._all_words: list[str] = []
        self._ready = False

    def load(self) -> None:
        """Load index.data into Trie + Bloom, build inverted index."""
        if not INDEX_PATH.exists() or not MEANING_PATH.exists():
            print("[!] No dictionary data found. Run the builder first:")
            print("    python -m engine.data.builder <dictionary.json>")
            self._ready = False
            return

        t0 = time.perf_counter()
        words: list[str] = []

        for word, offset, length in self.index_store.iterate():
            words.append(word)
            self.trie.insert(word)
            self.bloom.add(word)

            try:
                definition = self.meaning_store.read_entry(offset, length)
                self.inverted_index.add_document(word, definition)
            except Exception:
                pass

        self._all_words = words
        elapsed = time.perf_counter() - t0
        self._ready = True

        print(f"[OK] Loaded {len(words):,} words in {elapsed:.2f}s")
        print(f"    Trie: {self.trie.size:,} | Bloom: OK | Inverted Index: {self.inverted_index.term_count:,} terms")

    def get_definition_dict(self, word: str) -> dict | None:
        """Get a parsed definition dict for a word."""
        result = self.index_store.lookup(word)
        if not result:
            return None
        offset, length = result
        raw = self.meaning_store.read_entry(offset, length)
        if isinstance(raw, dict):
            return raw
        # If raw is a string, wrap it
        return {"word": word, "definitions": [str(raw)], "pos": [], "synonyms": [], "examples": [], "etymology": ""}

    @property
    def is_ready(self) -> bool:
        return self._ready


# ── App Lifecycle ─────────────────────────────────────────────────────

engine = LexiCoreEngine()


@asynccontextmanager
async def lifespan(app: FastAPI):
    engine.load()
    yield


app = FastAPI(
    title="LexiCore Engine",
    version="3.0.0",
    description="Blazing-fast offline dictionary & vocabulary engine",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Request Models ────────────────────────────────────────────────────

class OCRRequest(BaseModel):
    x1: int
    y1: int
    x2: int
    y2: int


class ExportRequest(BaseModel):
    deck_name: str = "LexiCore Deck"


class ReviewRequest(BaseModel):
    word: str
    grade: int  # 0-5


class SaveWordRequest(BaseModel):
    word: str
    definition: str | None = None


class CreateDeckRequest(BaseModel):
    name: str
    source: str = "manual"


class AddCardRequest(BaseModel):
    word: str
    definition: str | None = None


class CreateDeckFromWordsRequest(BaseModel):
    name: str
    words: list[str]
    count: int | None = None  # if None, use all words


class SubmitQuizRequest(BaseModel):
    deck_id: int | None = None
    answers: list[dict]  # [{word, user_answer, correct_answer, is_correct}]
    duration_s: float | None = None


class ProfileUpdateRequest(BaseModel):
    key: str
    value: str


class CreateProjectRequest(BaseModel):
    name: str
    description: str = ""
    color: str = "#7C4DFF"
    icon: str = "folder"


class UpdateProjectRequest(BaseModel):
    name: str | None = None
    description: str | None = None
    color: str | None = None
    icon: str | None = None


# ══════════════════════════════════════════════════════════════════════
# ORIGINAL ENDPOINTS (v2.0)
# ══════════════════════════════════════════════════════════════════════

# ── 1. Exact Search ──────────────────────────────────────────────────

@app.get("/api/search")
async def api_search_exact(q: str = Query(..., min_length=1)):
    t0 = time.perf_counter()

    if not engine.bloom.might_contain(q):
        return JSONResponse({
            "found": False,
            "query": q,
            "timing_ms": round((time.perf_counter() - t0) * 1000, 3),
        })

    cached = engine.cache.get(q.lower())
    if cached is not None:
        elapsed = round((time.perf_counter() - t0) * 1000, 3)
        return JSONResponse({
            "found": True,
            "query": q,
            "definition": cached,
            "source": "cache",
            "timing_ms": elapsed,
        })

    result = engine.index_store.lookup(q)
    if result is None:
        return JSONResponse({
            "found": False,
            "query": q,
            "timing_ms": round((time.perf_counter() - t0) * 1000, 3),
        })

    offset, length = result
    definition = engine.meaning_store.read_entry(offset, length)
    engine.cache.put(q.lower(), definition)
    engine.db.log_search(q)

    elapsed = round((time.perf_counter() - t0) * 1000, 3)
    return JSONResponse({
        "found": True,
        "query": q,
        "definition": definition,
        "source": "disk",
        "timing_ms": elapsed,
    })


# ── 2. Fuzzy Search ──────────────────────────────────────────────────

@app.get("/api/fuzzy")
async def api_search_fuzzy(q: str = Query(..., min_length=1)):
    t0 = time.perf_counter()
    results = fuzzy_search(q, engine._all_words, FUZZY_THRESHOLD)
    elapsed = round((time.perf_counter() - t0) * 1000, 3)
    return JSONResponse({
        "query": q,
        "suggestions": results[:20],
        "timing_ms": elapsed,
    })


# ── 3. Autocomplete ──────────────────────────────────────────────────

@app.get("/api/autocomplete")
async def api_autocomplete(
    prefix: str = Query(..., min_length=1),
    limit: int = Query(AUTOCOMPLETE_LIMIT, ge=1, le=50),
):
    t0 = time.perf_counter()
    results = engine.trie.autocomplete(prefix, limit)

    # Online fallback via Datamuse when local results are sparse
    if len(results) < 5:
        try:
            import httpx
            async with httpx.AsyncClient(timeout=2.0) as client:
                resp = await client.get(f"https://api.datamuse.com/sug?s={prefix}&max={limit}")
                if resp.status_code == 200:
                    online_words = [item["word"] for item in resp.json() if "word" in item]
                    # Merge without duplicates, local first
                    existing = set(r["word"] if isinstance(r, dict) else r for r in results)
                    for w in online_words:
                        if w.lower() not in existing and len(results) < limit:
                            results.append({"word": w, "source": "online"})
                            existing.add(w.lower())
        except Exception:
            pass  # Silently fall back to local-only

    elapsed = round((time.perf_counter() - t0) * 1000, 3)
    return JSONResponse({
        "prefix": prefix,
        "suggestions": results,
        "timing_ms": elapsed,
    })


# ── 4. Fetch Audio ───────────────────────────────────────────────────

@app.get("/api/audio")
async def api_fetch_audio(q: str = Query(..., min_length=1),
                          force: bool = Query(False)):
    filepath = fetch_audio(q, force_network=force)
    if filepath and Path(filepath).exists():
        return FileResponse(filepath, media_type="audio/mpeg")
    return JSONResponse({"error": "Audio not available"}, status_code=404)


# ── 5. Fetch Image ───────────────────────────────────────────────────

@app.get("/api/image")
async def api_fetch_image(q: str = Query(..., min_length=1)):
    filepath = await async_fetch_image(q)
    if filepath and Path(filepath).exists():
        return FileResponse(filepath, media_type="image/jpeg")
    return JSONResponse({"error": "Image not available"}, status_code=404)


# ── 6. OCR Screen Region ─────────────────────────────────────────────

@app.post("/api/ocr")
async def api_ocr(req: OCRRequest):
    result = ocr_screen_region(req.x1, req.y1, req.x2, req.y2)
    return JSONResponse(result)


# ── 7. Export to Anki ─────────────────────────────────────────────────

@app.post("/api/export")
async def api_export(req: ExportRequest):
    saved = engine.db.get_saved_words()
    if not saved:
        return JSONResponse({"error": "No saved words to export"}, status_code=400)

    cards = [
        {
            "word": w["word"],
            "definition": w.get("definition", ""),
            "audio_path": w.get("audio_path", ""),
            "image_path": w.get("image_path", ""),
        }
        for w in saved
    ]

    filepath = export_to_anki(req.deck_name, cards)
    return FileResponse(filepath, filename=f"{req.deck_name}.apkg",
                        media_type="application/octet-stream")


# ── Reverse Search ────────────────────────────────────────────────────

@app.get("/api/reverse")
async def api_reverse_search(q: str = Query(..., min_length=2),
                              limit: int = Query(10, ge=1, le=50)):
    t0 = time.perf_counter()
    results = engine.inverted_index.search(q, limit)
    elapsed = round((time.perf_counter() - t0) * 1000, 3)
    return JSONResponse({
        "query": q,
        "results": [{"word": w, "score": round(s, 4)} for w, s in results],
        "timing_ms": elapsed,
    })


# ── Learning Endpoints ────────────────────────────────────────────────

@app.post("/api/review")
async def api_review(req: ReviewRequest):
    result = engine.sm2.review(req.word, req.grade)
    return JSONResponse(result)


@app.get("/api/due")
async def api_due_reviews():
    return JSONResponse({"due": engine.sm2.get_due()})


@app.get("/api/stats")
async def api_stats():
    streak_data = engine.streaks.get_stats()
    cache_data = engine.cache.stats
    return JSONResponse({
        "learning": streak_data,
        "cache": cache_data,
        "dictionary_size": engine.trie.size,
        "inverted_index_terms": engine.inverted_index.term_count,
        "ready": engine.is_ready,
    })


@app.post("/api/save")
async def api_save_word(req: SaveWordRequest):
    engine.db.save_word(req.word, req.definition)
    return JSONResponse({"saved": True, "word": req.word})


@app.get("/api/saved")
async def api_get_saved():
    return JSONResponse({"words": engine.db.get_saved_words()})


@app.delete("/api/saved/{word}")
async def api_delete_saved(word: str):
    deleted = engine.db.delete_saved_word(word)
    return JSONResponse({"deleted": deleted, "word": word})


@app.get("/api/history")
async def api_history(limit: int = Query(50, ge=1, le=200)):
    return JSONResponse({"history": engine.db.get_search_history(limit)})


@app.get("/api/wotd")
async def api_word_of_the_day(mode: str = Query("local"), hours: int = Query(2, ge=1, le=12)):
    """Word of the Day.
    
    - mode=local  → pick from local dictionary (2-hour rotation)
    - mode=online → pick curated word + Cambridge definition
    """
    from engine.learning.wotd import get_wotd_for_period, get_curated_wotd

    if mode == "online":
        word = get_curated_wotd(hours=hours)
        # Try Cambridge for full definition
        try:
            online_def = await lookup_online(word)
            if online_def:
                return JSONResponse({"word": word, "definition": online_def, "source": "online", "rotation_hours": hours})
        except Exception:
            pass
        # Fallback to local definition if available
        result = engine.index_store.lookup(word)
        definition = None
        if result:
            offset, length = result
            definition = engine.meaning_store.read_entry(offset, length)
        return JSONResponse({"word": word, "definition": definition, "source": "curated", "rotation_hours": hours})
    else:
        word = get_wotd_for_period(
            word_iterator=lambda: engine._all_words,
            is_learned=lambda w: engine.db.is_saved(w),
            hours=hours,
        )
        if word:
            result = engine.index_store.lookup(word)
            definition = None
            if result:
                offset, length = result
                definition = engine.meaning_store.read_entry(offset, length)
            return JSONResponse({"word": word, "definition": definition, "source": "local", "rotation_hours": hours})
        return JSONResponse({"word": None, "definition": None})


# ══════════════════════════════════════════════════════════════════════
# v3.0 — ONLINE SEARCH (Cambridge Dictionary Fallback)
# ══════════════════════════════════════════════════════════════════════

@app.get("/api/search/online")
async def api_search_online(q: str = Query(..., min_length=1)):
    """Search online when word is not in local database."""
    t0 = time.perf_counter()
    result = await lookup_online(q)
    elapsed = round((time.perf_counter() - t0) * 1000, 3)

    if result:
        engine.db.log_search(q)
        return JSONResponse({
            "found": True,
            "query": q,
            "definition": result,
            "source": "online",
            "timing_ms": elapsed,
        })
    return JSONResponse({
        "found": False,
        "query": q,
        "source": "online",
        "timing_ms": elapsed,
    })


# ── Pronunciation Audio URL ──────────────────────────────────────────

@app.get("/api/pronounce")
async def api_pronounce(q: str = Query(..., min_length=1),
                         accent: str = Query("us")):
    """Get pronunciation audio URL (US or UK accent)."""
    url = await get_pronunciation_url(q, accent)
    return JSONResponse({
        "word": q,
        "accent": accent,
        "audio_url": url,
    })


# ══════════════════════════════════════════════════════════════════════
# v3.0 — FLASHCARD DECKS
# ══════════════════════════════════════════════════════════════════════

@app.get("/api/decks")
async def api_get_decks():
    return JSONResponse({"decks": engine.db.get_decks()})


@app.post("/api/decks")
async def api_create_deck(req: CreateDeckRequest):
    deck_id = engine.db.create_deck(req.name, req.source)
    return JSONResponse({"id": deck_id, "name": req.name})


@app.delete("/api/decks/{deck_id}")
async def api_delete_deck(deck_id: int):
    deleted = engine.db.delete_deck(deck_id)
    return JSONResponse({"deleted": deleted})


@app.get("/api/decks/{deck_id}/cards")
async def api_get_cards(deck_id: int):
    cards = engine.db.get_cards(deck_id)
    return JSONResponse({"cards": cards})


@app.post("/api/decks/{deck_id}/cards")
async def api_add_card(deck_id: int, req: AddCardRequest):
    # Auto-fill definition from local DB if not provided
    definition = req.definition
    if not definition:
        defn = engine.get_definition_dict(req.word)
        if defn and defn.get("definitions"):
            definition = defn["definitions"][0]

    card_id = engine.db.add_card(deck_id, req.word, definition)
    return JSONResponse({"id": card_id, "word": req.word, "definition": definition})


@app.delete("/api/cards/{card_id}")
async def api_delete_card(card_id: int):
    deleted = engine.db.delete_card(card_id)
    return JSONResponse({"deleted": deleted})


@app.post("/api/decks/from-words")
async def api_create_deck_from_words(req: CreateDeckFromWordsRequest):
    """Create a deck from a list of words, auto-filling definitions."""
    deck_id = engine.db.create_deck(req.name, "manual")
    words_to_use = req.words[:req.count] if req.count else req.words
    added = 0

    for word in words_to_use:
        defn = engine.get_definition_dict(word)
        definition = defn["definitions"][0] if defn and defn.get("definitions") else None
        engine.db.add_card(deck_id, word, definition)
        added += 1

    return JSONResponse({"deck_id": deck_id, "cards_added": added})


# ══════════════════════════════════════════════════════════════════════
# v3.0 — QUIZ SYSTEM
# ══════════════════════════════════════════════════════════════════════

@app.get("/api/quiz/generate")
async def api_generate_quiz(deck_id: int | None = Query(None),
                             count: int = Query(10, ge=1, le=50)):
    """Generate a multiple-choice quiz from saved words or a deck."""
    if deck_id is not None:
        cards = engine.db.get_cards(deck_id)
        words = [{"word": c["word"], "definition": c.get("definition", "")} for c in cards]
    else:
        saved = engine.db.get_saved_words()
        words = [{"word": w["word"], "definition": w.get("definition", "")} for w in saved]

    if len(words) < 4:
        return JSONResponse(
            {"error": "Need at least 4 words to generate a quiz"},
            status_code=400,
        )

    questions = engine.db.generate_quiz(words, count)
    return JSONResponse({"questions": questions, "total": len(questions)})


@app.post("/api/quiz/submit")
async def api_submit_quiz(req: SubmitQuizRequest):
    """Submit quiz results and get feedback."""
    correct = sum(1 for a in req.answers if a.get("is_correct"))
    total = len(req.answers)
    score_pct = round((correct / total) * 100, 1) if total > 0 else 0

    quiz_id = engine.db.create_quiz_result(
        req.deck_id, total, correct, score_pct, req.duration_s,
    )

    for answer in req.answers:
        engine.db.add_quiz_answer(
            quiz_id,
            answer.get("word", ""),
            answer.get("user_answer"),
            answer.get("correct_answer", ""),
            answer.get("is_correct", False),
            answer.get("explanation"),
        )

    # Check for pet unlocks
    newly_eligible = engine.db.check_pet_eligibility()
    new_pets = []
    for pet_id in newly_eligible:
        if engine.db.unlock_pet(pet_id):
            new_pets.append(pet_id)

    return JSONResponse({
        "quiz_id": quiz_id,
        "correct": correct,
        "total": total,
        "score_pct": score_pct,
        "new_pets_unlocked": new_pets,
    })


@app.get("/api/quiz/history")
async def api_quiz_history(limit: int = Query(20, ge=1, le=100)):
    return JSONResponse({"history": engine.db.get_quiz_history(limit)})


@app.get("/api/quiz/{quiz_id}/answers")
async def api_quiz_detail(quiz_id: int):
    answers = engine.db.get_quiz_answers(quiz_id)
    return JSONResponse({"answers": answers})


# ══════════════════════════════════════════════════════════════════════
# v3.0 — FILE IMPORT
# ══════════════════════════════════════════════════════════════════════

@app.post("/api/import/file")
async def api_import_file(file: UploadFile = File(...)):
    """Import words from a text file (one word per line or JSON)."""
    content = await file.read()
    text = content.decode("utf-8", errors="ignore")
    filename = file.filename or "unknown.txt"

    # Parse words
    words = []
    if filename.endswith(".json"):
        try:
            data = json.loads(text)
            if isinstance(data, list):
                words = data
            elif isinstance(data, dict):
                words = list(data.keys())
        except json.JSONDecodeError:
            return JSONResponse({"error": "Invalid JSON"}, status_code=400)
    else:
        # Text file: one word per line
        words = [line.strip() for line in text.splitlines() if line.strip()]

    if not words:
        return JSONResponse({"error": "No words found in file"}, status_code=400)

    # Save to DB
    file_id = engine.db.add_imported_file(filename, len(words))
    for word in words:
        if isinstance(word, str):
            defn = engine.get_definition_dict(word)
            definition = None
            if defn and defn.get("definitions"):
                definition = defn["definitions"][0] if isinstance(defn["definitions"], list) else str(defn["definitions"])
            engine.db.save_word(word, definition=definition, source_file=filename)

    return JSONResponse({
        "file_id": file_id,
        "filename": filename,
        "words_imported": len(words),
    })


@app.get("/api/import/files")
async def api_get_imported_files():
    files = engine.db.get_imported_files()
    return JSONResponse({"files": files})


@app.delete("/api/import/files/{file_id}")
async def api_delete_imported_file(file_id: int):
    deleted = engine.db.delete_imported_file(file_id)
    return JSONResponse({"deleted": deleted})


@app.get("/api/import/files/{file_id}/words")
async def api_get_file_words(file_id: int):
    files = engine.db.get_imported_files()
    target = next((f for f in files if f["id"] == file_id), None)
    if not target:
        return JSONResponse({"error": "File not found"}, status_code=404)
    words = engine.db.get_words_by_source(target["filename"])
    return JSONResponse({"words": words, "filename": target["filename"]})


# ══════════════════════════════════════════════════════════════════════
# v3.0 — USER PROFILE
# ══════════════════════════════════════════════════════════════════════

@app.get("/api/profile")
async def api_get_profile():
    profile = engine.db.get_profile()
    return JSONResponse({"profile": profile})


@app.put("/api/profile")
async def api_update_profile(req: ProfileUpdateRequest):
    engine.db.set_profile(req.key, req.value)
    return JSONResponse({"updated": True, "key": req.key})


# ══════════════════════════════════════════════════════════════════════
# v3.0 — STREAK PETS
# ══════════════════════════════════════════════════════════════════════

@app.get("/api/pets")
async def api_get_all_pets():
    """Get all pets with unlock status."""
    unlocked = {p["pet_id"] for p in engine.db.get_unlocked_pets()}
    pets = []
    for pet_id, info in engine.db.PETS.items():
        streak_req = info.get("streak_req", 0)
        req_text = f"Reach {streak_req}-day streak" if streak_req > 0 else "Get 3 perfect quiz scores"
        pets.append({
            "id": pet_id,
            "name": info["name"],
            "emoji": info.get("emoji", ""),
            "description": info.get("desc", ""),
            "requirement": req_text,
            "streak_req": streak_req,
            "unlocked": pet_id in unlocked,
        })
    return JSONResponse({"pets": pets})


@app.get("/api/pets/unlocked")
async def api_get_unlocked_pets():
    return JSONResponse({"pets": engine.db.get_unlocked_pets()})


@app.post("/api/pets/check")
async def api_check_pet_unlocks():
    """Check and unlock any newly eligible pets."""
    newly_eligible = engine.db.check_pet_eligibility()
    new_pets = []
    for pet_id in newly_eligible:
        if engine.db.unlock_pet(pet_id):
            new_pets.append(pet_id)
    return JSONResponse({"new_pets": new_pets})


# ══════════════════════════════════════════════════════════════════════
# v3.0 — PERFORMANCE ANALYTICS
# ══════════════════════════════════════════════════════════════════════

@app.get("/api/performance")
async def api_performance():
    return JSONResponse(engine.db.get_performance_summary())


@app.get("/api/performance/history")
async def api_performance_history():
    """Get daily performance over time."""
    with engine.db._cursor() as cur:
        cur.execute(
            "SELECT date_key, words_learned, searches, exp_earned "
            "FROM streaks ORDER BY date_key DESC LIMIT 30"
        )
        days = [dict(row) for row in cur.fetchall()]
    return JSONResponse({"history": days})


# ══════════════════════════════════════════════════════════════════════
# v3.0 — WELCOME MESSAGES
# ══════════════════════════════════════════════════════════════════════

@app.get("/api/welcome")
async def api_welcome():
    """Get personalized welcome message."""
    import random
    name = engine.db.get_display_name()
    streak = engine.db.get_streak_days()

    messages = [
        f"{name} returns!",
        f"Welcome back, {name}!",
        f"Ready to learn, {name}?",
        f"Good to see you, {name}!",
        f"Let's build your vocabulary, {name}!",
        f"Knowledge awaits, {name}!",
        f"Hey {name}, what shall we explore today?",
        f"The scholar returns!",
    ]

    if streak > 0:
        messages.extend([
            f"{streak}-day streak! Keep going, {name}!",
            f"On fire! {streak} days strong, {name}!",
        ])

    return JSONResponse({
        "message": random.choice(messages),
        "name": name,
        "streak": streak,
    })


# ── WebSocket (realtime autocomplete) ─────────────────────────────────

@app.websocket("/ws")
async def websocket_endpoint(ws: WebSocket):
    await ws.accept()
    try:
        while True:
            data = await ws.receive_json()
            action = data.get("action", "")

            if action == "autocomplete":
                prefix = data.get("prefix", "")
                limit = data.get("limit", AUTOCOMPLETE_LIMIT)
                t0 = time.perf_counter()
                results = engine.trie.autocomplete(prefix, limit)
                elapsed = round((time.perf_counter() - t0) * 1000, 3)
                await ws.send_json({
                    "action": "autocomplete",
                    "prefix": prefix,
                    "suggestions": results,
                    "timing_ms": elapsed,
                })

            elif action == "search":
                query = data.get("query", "")
                t0 = time.perf_counter()

                if not engine.bloom.might_contain(query):
                    await ws.send_json({
                        "action": "search",
                        "found": False,
                        "query": query,
                        "timing_ms": round((time.perf_counter() - t0) * 1000, 3),
                    })
                    continue

                cached = engine.cache.get(query.lower())
                if cached:
                    await ws.send_json({
                        "action": "search",
                        "found": True,
                        "query": query,
                        "definition": cached,
                        "source": "cache",
                        "timing_ms": round((time.perf_counter() - t0) * 1000, 3),
                    })
                    continue

                result = engine.index_store.lookup(query)
                if result:
                    offset, length = result
                    definition = engine.meaning_store.read_entry(offset, length)
                    engine.cache.put(query.lower(), definition)
                    engine.db.log_search(query)
                    await ws.send_json({
                        "action": "search",
                        "found": True,
                        "query": query,
                        "definition": definition,
                        "source": "disk",
                        "timing_ms": round((time.perf_counter() - t0) * 1000, 3),
                    })
                else:
                    await ws.send_json({
                        "action": "search",
                        "found": False,
                        "query": query,
                        "timing_ms": round((time.perf_counter() - t0) * 1000, 3),
                    })

    except WebSocketDisconnect:
        pass


# ══════════════════════════════════════════════════════════════════════
# v3.1 — PROJECTS
# ══════════════════════════════════════════════════════════════════════

@app.get("/api/projects")
async def api_get_projects():
    return {"projects": engine.db.get_projects()}


@app.post("/api/projects")
async def api_create_project(req: CreateProjectRequest):
    pid = engine.db.create_project(req.name, req.description, req.color, req.icon)
    return {"id": pid, "status": "created"}


@app.get("/api/projects/{project_id}")
async def api_get_project(project_id: int):
    p = engine.db.get_project(project_id)
    if not p:
        return JSONResponse({"error": "Project not found"}, status_code=404)
    return p


@app.put("/api/projects/{project_id}")
async def api_update_project(project_id: int, req: UpdateProjectRequest):
    updates = {k: v for k, v in req.model_dump().items() if v is not None}
    engine.db.update_project(project_id, **updates)
    return {"status": "updated"}


@app.delete("/api/projects/{project_id}")
async def api_delete_project(project_id: int):
    engine.db.delete_project(project_id)
    return {"status": "deleted"}


@app.post("/api/projects/{project_id}/deck")
async def api_create_project_deck(project_id: int, req: CreateDeckRequest):
    deck_id = engine.db.create_deck(req.name, source=f"project:{project_id}")
    return {"deck_id": deck_id, "project_id": project_id}


# ══════════════════════════════════════════════════════════════════════
# v3.1 — AVATAR UPLOAD
# ══════════════════════════════════════════════════════════════════════

@app.post("/api/profile/avatar")
async def api_upload_avatar(file: UploadFile = File(...)):
    avatar_dir = DATA_DIR / "avatars"
    avatar_dir.mkdir(exist_ok=True)
    ext = Path(file.filename or "avatar.png").suffix or ".png"
    avatar_path = avatar_dir / f"user_avatar{ext}"
    content = await file.read()
    avatar_path.write_bytes(content)
    engine.db.set_profile("avatar_path", str(avatar_path))
    return {"status": "uploaded", "path": str(avatar_path)}


@app.get("/api/profile/avatar")
async def api_get_avatar():
    profile = engine.db.get_profile()
    avatar_path = profile.get("avatar_path", "")
    if avatar_path and Path(avatar_path).exists():
        return FileResponse(avatar_path)
    return JSONResponse({"error": "No custom avatar"}, status_code=404)


# ── XP & Leveling ──────────────────────────────────────────────────

from engine.learning.xp_engine import (
    xp_progress, calculate_award, word_mastery_tier,
    XP_SEARCH, XP_SAVE, XP_QUIZ_CORRECT, XP_QUIZ_PERFECT,
    XP_DAILY_LOGIN, XP_FLASHCARD, XP_DECK_COMPLETE,
)


@app.get("/api/xp/status")
async def api_xp_status():
    total_xp = engine.db.get_total_exp()
    streak = engine.db.get_streak_days()
    progress = xp_progress(total_xp)
    progress["streak_days"] = streak
    return JSONResponse(progress)


@app.post("/api/xp/award")
async def api_xp_award(req: dict):
    action = req.get("action", "")
    streak = engine.db.get_streak_days()
    amount = calculate_award(action, streak)
    if amount > 0:
        engine.db.add_exp(amount)

    # Track quest progress
    quest_action_map = {
        "search": "search", "save": "save", "quiz": "quiz",
        "quiz_correct": "quiz_correct", "daily_login": "streak",
    }
    quest_action = quest_action_map.get(action, action)
    completed_quests = engine.db.increment_quest(quest_action)

    # Award bonus XP for completed quests
    quest_bonus = 0
    for q in completed_quests:
        quest_bonus += q.get("xp", 0)
    if quest_bonus > 0:
        engine.db.add_exp(quest_bonus)

    total_xp = engine.db.get_total_exp()
    return JSONResponse({
        "awarded": amount,
        "quest_bonus": quest_bonus,
        "completed_quests": [q["id"] for q in completed_quests],
        "total_xp": total_xp,
        **xp_progress(total_xp),
    })


@app.get("/api/quests")
async def api_get_quests():
    """Get all quests with current progress."""
    quests = engine.db.get_quest_progress()
    return JSONResponse({"quests": quests})


# ── Run ───────────────────────────────────────────────────────────────

def start():
    import uvicorn
    uvicorn.run(app, host=API_HOST, port=API_PORT)


if __name__ == "__main__":
    start()

