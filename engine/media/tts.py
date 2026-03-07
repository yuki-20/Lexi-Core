"""
LexiCore — Text-to-Speech (gTTS)
=================================
Fetches pronunciation audio, caches in media_cache/.
"""

from __future__ import annotations

from pathlib import Path

from engine.config import MEDIA_CACHE_DIR


def fetch_audio(word: str, force_network: bool = False) -> str:
    """Return the filepath to the pronunciation MP3 for *word*.

    Checks media_cache/ first.  Falls back to gTTS if not cached.
    """
    safe_name = "".join(c if c.isalnum() else "_" for c in word.lower())
    cache_path = MEDIA_CACHE_DIR / f"{safe_name}.mp3"

    if cache_path.exists() and not force_network:
        return str(cache_path)

    try:
        from gtts import gTTS
        tts = gTTS(text=word, lang="en")
        tts.save(str(cache_path))
        return str(cache_path)
    except Exception as e:
        # Graceful degradation — return empty if network fails
        return ""
