"""
LexiCore — Cambridge Dictionary Online Fallback (v5.6)
=======================================================
Multi-source word lookup with retry logic for reliable digest.
Sources: dictionaryapi.dev (primary), Cambridge HTML scraping (fallback).
"""

from __future__ import annotations

import re
import asyncio
from typing import Any

import aiohttp


_DICT_API_URL = "https://api.dictionaryapi.dev/api/v2/entries/en/{word}"
_CAMBRIDGE_URL = "https://dictionary.cambridge.org/dictionary/english/{word}"

_HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
                  "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
}


async def _lookup_dictapi(word: str, session: aiohttp.ClientSession) -> dict[str, Any] | None:
    """Primary lookup via dictionaryapi.dev."""
    url = _DICT_API_URL.format(word=word.lower().strip())
    try:
        async with session.get(url, timeout=aiohttp.ClientTimeout(total=10)) as resp:
            if resp.status != 200:
                return None
            data = await resp.json()
    except Exception:
        return None

    if not data or not isinstance(data, list):
        return None

    return _parse_dictapi_response(data[0], word)


def _parse_dictapi_response(entry: dict, word: str) -> dict[str, Any] | None:
    """Parse a dictionaryapi.dev entry into our standard format."""
    result: dict[str, Any] = {
        "word": entry.get("word", word),
        "phonetic": entry.get("phonetic", ""),
        "pos": [],
        "definitions": [],
        "synonyms": [],
        "examples": [],
        "etymology": "",
        "audio_us": "",
        "audio_uk": "",
    }

    for p in entry.get("phonetics", []):
        audio = p.get("audio", "")
        if audio:
            if "-us" in audio or "us/" in audio:
                result["audio_us"] = audio
            elif "-uk" in audio or "uk/" in audio:
                result["audio_uk"] = audio
            elif not result["audio_us"]:
                result["audio_us"] = audio

    for meaning in entry.get("meanings", []):
        pos = meaning.get("partOfSpeech", "")
        if pos and pos not in result["pos"]:
            result["pos"].append(pos)

        for defn in meaning.get("definitions", []):
            d = defn.get("definition", "")
            if d:
                result["definitions"].append(d)
            ex = defn.get("example", "")
            if ex:
                result["examples"].append(ex)

        for syn in meaning.get("synonyms", []):
            if syn not in result["synonyms"]:
                result["synonyms"].append(syn)

    result["definitions"] = result["definitions"][:5]
    result["examples"] = result["examples"][:3]
    result["synonyms"] = result["synonyms"][:8]

    return result if result["definitions"] else None


async def _lookup_cambridge_html(word: str, session: aiohttp.ClientSession) -> dict[str, Any] | None:
    """Fallback: scrape Cambridge Dictionary HTML for definitions."""
    url = _CAMBRIDGE_URL.format(word=word.lower().strip().replace(" ", "-"))
    try:
        async with session.get(url, headers=_HEADERS, timeout=aiohttp.ClientTimeout(total=10)) as resp:
            if resp.status != 200:
                return None
            html = await resp.text()
    except Exception:
        return None

    # Extract definitions from Cambridge HTML
    definitions = []
    # Cambridge uses <div class="def ddef_d db"> for definitions
    def_pattern = re.compile(r'<div class="def ddef_d db">(.*?)</div>', re.DOTALL)
    for match in def_pattern.finditer(html):
        text = re.sub(r'<[^>]+>', '', match.group(1)).strip()
        text = text.rstrip(':').strip()
        if text and len(text) > 3:
            definitions.append(text)

    # Also try <span class="def-body ddef_b"> pattern
    if not definitions:
        body_pattern = re.compile(r'class="def-body[^"]*"[^>]*>(.*?)</div>', re.DOTALL)
        for match in body_pattern.finditer(html):
            text = re.sub(r'<[^>]+>', '', match.group(1)).strip()
            text = text.rstrip(':').strip()
            if text and len(text) > 5:
                definitions.append(text)

    if not definitions:
        return None

    # Extract part of speech
    pos = []
    pos_pattern = re.compile(r'class="pos dpos"[^>]*>(.*?)</span>', re.DOTALL)
    for match in pos_pattern.finditer(html):
        p = re.sub(r'<[^>]+>', '', match.group(1)).strip()
        if p and p not in pos:
            pos.append(p)

    return {
        "word": word,
        "phonetic": "",
        "pos": pos[:3],
        "definitions": definitions[:5],
        "synonyms": [],
        "examples": [],
        "etymology": "",
        "audio_us": "",
        "audio_uk": "",
    }


async def lookup_online(word: str) -> dict[str, Any] | None:
    """Look up a word with retry logic and multi-source fallback.

    Strategy:
    1. Try dictionaryapi.dev (up to 2 attempts)
    2. If that fails, try Cambridge HTML scraping
    """
    async with aiohttp.ClientSession() as session:
        # Attempt 1: dictionaryapi.dev
        result = await _lookup_dictapi(word, session)
        if result:
            return result

        # Attempt 2: retry dictionaryapi.dev after short delay
        await asyncio.sleep(0.5)
        result = await _lookup_dictapi(word, session)
        if result:
            return result

        # Attempt 3: Cambridge HTML scraping fallback
        result = await _lookup_cambridge_html(word, session)
        if result:
            return result

    return None


async def get_pronunciation_url(word: str, accent: str = "us") -> str | None:
    """Get the pronunciation audio URL for a word.

    Args:
        word: The word to pronounce.
        accent: 'us' or 'uk'.
    """
    result = await lookup_online(word)
    if not result:
        return None

    if accent.lower() == "uk":
        return result.get("audio_uk") or result.get("audio_us") or None
    return result.get("audio_us") or result.get("audio_uk") or None
