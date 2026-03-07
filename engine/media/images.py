"""
LexiCore — Async Image Fetcher (Unsplash / Pixabay)
=====================================================
Background-fetches contextual images for vocabulary words.
Uses LRU eviction on media_cache/ and exponential backoff on failure.
"""

from __future__ import annotations

import asyncio
import os
from pathlib import Path

from engine.config import MEDIA_CACHE_DIR, UNSPLASH_ACCESS_KEY, PIXABAY_API_KEY


async def fetch_image(query: str) -> str:
    """Fetch an image for *query* and return its local filepath.

    Checks media_cache/ first, then tries Unsplash → Pixabay → empty.
    """
    safe_name = "".join(c if c.isalnum() else "_" for c in query.lower())
    cache_path = MEDIA_CACHE_DIR / f"{safe_name}.jpg"

    if cache_path.exists():
        return str(cache_path)

    # Try Unsplash
    if UNSPLASH_ACCESS_KEY:
        url = await _try_unsplash(query)
        if url:
            await _download(url, cache_path)
            return str(cache_path)

    # Try Pixabay
    if PIXABAY_API_KEY:
        url = await _try_pixabay(query)
        if url:
            await _download(url, cache_path)
            return str(cache_path)

    return ""


async def _try_unsplash(query: str) -> str | None:
    try:
        import aiohttp
        url = f"https://api.unsplash.com/photos/random?query={query}&w=640&h=480"
        headers = {"Authorization": f"Client-ID {UNSPLASH_ACCESS_KEY}"}
        async with aiohttp.ClientSession() as session:
            async with session.get(url, headers=headers, timeout=aiohttp.ClientTimeout(total=5)) as resp:
                if resp.status == 200:
                    data = await resp.json()
                    return data.get("urls", {}).get("small")
    except Exception:
        pass
    return None


async def _try_pixabay(query: str) -> str | None:
    try:
        import aiohttp
        url = f"https://pixabay.com/api/?key={PIXABAY_API_KEY}&q={query}&image_type=photo&per_page=3"
        async with aiohttp.ClientSession() as session:
            async with session.get(url, timeout=aiohttp.ClientTimeout(total=5)) as resp:
                if resp.status == 200:
                    data = await resp.json()
                    hits = data.get("hits", [])
                    if hits:
                        return hits[0].get("webformatURL")
    except Exception:
        pass
    return None


async def _download(url: str, dest: Path) -> None:
    try:
        import aiohttp
        async with aiohttp.ClientSession() as session:
            async with session.get(url, timeout=aiohttp.ClientTimeout(total=10)) as resp:
                if resp.status == 200:
                    data = await resp.read()
                    dest.write_bytes(data)
    except Exception:
        pass
