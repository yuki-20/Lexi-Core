"""LexiCore Engine — Configuration & Constants."""

from pathlib import Path
import os

# ── Paths ──────────────────────────────────────────────────────────────
ROOT_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = ROOT_DIR / "data"
MEDIA_CACHE_DIR = DATA_DIR / "media_cache"

INDEX_PATH = DATA_DIR / "index.data"
MEANING_PATH = DATA_DIR / "meaning.bin"
DB_PATH = DATA_DIR / "user_progress.db"

# Ensure runtime directories exist
DATA_DIR.mkdir(exist_ok=True)
MEDIA_CACHE_DIR.mkdir(exist_ok=True)

# ── Index Record Layout ───────────────────────────────────────────────
WORD_KEY_SIZE = 64          # bytes — max word length (UTF-8 padded)
OFFSET_SIZE = 8             # bytes — uint64 byte-offset into meaning.bin
LENGTH_SIZE = 4             # bytes — uint32 bit-length of compressed entry
RECORD_SIZE = WORD_KEY_SIZE + OFFSET_SIZE + LENGTH_SIZE   # 76 bytes

# ── Bloom Filter ──────────────────────────────────────────────────────
BLOOM_SIZE = 1 << 20        # ~1 million bits
BLOOM_HASH_COUNT = 7        # number of hash functions

# ── LRU Cache ─────────────────────────────────────────────────────────
LRU_CAPACITY = 2048         # max cached definitions in RAM

# ── Media Cache ───────────────────────────────────────────────────────
MEDIA_CACHE_MAX_MB = 500    # LRU eviction threshold

# ── API ───────────────────────────────────────────────────────────────
API_HOST = "127.0.0.1"
API_PORT = 8741

# ── External API Keys (env-var driven) ────────────────────────────────
UNSPLASH_ACCESS_KEY = os.getenv("LEXICORE_UNSPLASH_KEY", "")
PIXABAY_API_KEY = os.getenv("LEXICORE_PIXABAY_KEY", "")

# ── Search ────────────────────────────────────────────────────────────
AUTOCOMPLETE_LIMIT = 10
FUZZY_THRESHOLD = 2         # max Levenshtein distance considered a match
