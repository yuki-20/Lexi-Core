"""
LexiCore — FastAPI Main Server
================================
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

from fastapi import FastAPI, Query, WebSocket, WebSocketDisconnect
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

            # Build inverted index from definitions
            try:
                definition = self.meaning_store.read_entry(offset, length)
                self.inverted_index.add_document(word, definition)
            except Exception:
                pass

        self._all_words = words
        elapsed = time.perf_counter() - t0
        self._ready = True

        print(f"[✓] Loaded {len(words):,} words in {elapsed:.2f}s")
        print(f"    Trie: {self.trie.size:,} | Bloom: OK | Inverted Index: {self.inverted_index.term_count:,} terms")

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
    version="2.0.0",
    description="Blazing-fast offline dictionary & vocabulary engine",
    lifespan=lifespan,
)

# CORS — allow the Tauri/React frontend
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


# ── 1. Exact Search ──────────────────────────────────────────────────

@app.get("/api/search")
async def api_search_exact(q: str = Query(..., min_length=1)):
    t0 = time.perf_counter()

    # Bloom fast-fail
    if not engine.bloom.might_contain(q):
        return JSONResponse({
            "found": False,
            "query": q,
            "timing_ms": round((time.perf_counter() - t0) * 1000, 3),
        })

    # LRU cache check
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

    # Index lookup
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


@app.get("/api/history")
async def api_history(limit: int = Query(50, ge=1, le=200)):
    return JSONResponse({"history": engine.db.get_search_history(limit)})


@app.get("/api/wotd")
async def api_word_of_the_day():
    word = get_word_of_the_day(
        word_iterator=lambda: engine._all_words,
        is_learned=lambda w: engine.db.is_saved(w),
    )
    if word:
        # Also fetch definition
        result = engine.index_store.lookup(word)
        definition = None
        if result:
            offset, length = result
            definition = engine.meaning_store.read_entry(offset, length)
        return JSONResponse({"word": word, "definition": definition})
    return JSONResponse({"word": None, "definition": None})


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


# ── Run ───────────────────────────────────────────────────────────────

def start():
    import uvicorn
    uvicorn.run(app, host=API_HOST, port=API_PORT)


if __name__ == "__main__":
    start()
