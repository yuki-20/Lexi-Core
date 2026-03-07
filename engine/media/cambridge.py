"""
LexiCore — Cambridge Dictionary Online Fallback
=================================================
When a word is not found in the local database, query Cambridge Dictionary
via their public API/web scraping to get the definition.
"""

from __future__ import annotations

import re
from typing import Any

import aiohttp


_CAMBRIDGE_URL = "https://dictionary.cambridge.org/dictionary/english/{word}"
_DICT_API_URL = "https://api.dictionaryapi.dev/api/v2/entries/en/{word}"


async def lookup_online(word: str) -> dict[str, Any] | None:
    """Look up a word from the free Dictionary API (dictionaryapi.dev).

    Returns a dict compatible with local search results, or None if not found.
    """
    url = _DICT_API_URL.format(word=word.lower().strip())

    try:
        async with aiohttp.ClientSession() as session:
            async with session.get(url, timeout=aiohttp.ClientTimeout(total=8)) as resp:
                if resp.status != 200:
                    return None
                data = await resp.json()
    except Exception:
        return None

    if not data or not isinstance(data, list):
        return None

    entry = data[0]
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

    # Extract phonetics / audio URLs
    for p in entry.get("phonetics", []):
        audio = p.get("audio", "")
        if audio:
            if "-us" in audio or "us/" in audio:
                result["audio_us"] = audio
            elif "-uk" in audio or "uk/" in audio:
                result["audio_uk"] = audio
            elif not result["audio_us"]:
                result["audio_us"] = audio

    # Extract meanings
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

    # Limit results
    result["definitions"] = result["definitions"][:5]
    result["examples"] = result["examples"][:3]
    result["synonyms"] = result["synonyms"][:8]

    return result if result["definitions"] else None


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
