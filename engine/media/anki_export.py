"""
LexiCore — Anki .apkg Export
==============================
Packages saved words, definitions, cached audio, and images into
a SQLite-based .apkg file compatible with Anki.
"""

from __future__ import annotations

import json
import os
import sqlite3
import tempfile
import time
import zipfile
from pathlib import Path
from typing import Any

from engine.config import DATA_DIR


def export_to_anki(
    deck_name: str,
    cards: list[dict[str, Any]],
    output_dir: Path | None = None,
) -> str:
    """Build an .apkg file from a list of card dicts.

    Each card dict should have:
      - word: str
      - definition: str
      - audio_path: str (optional)
      - image_path: str (optional)

    Returns the filepath of the generated .apkg.
    """
    output_dir = output_dir or DATA_DIR
    output_path = output_dir / f"{deck_name}.apkg"

    deck_id = abs(hash(deck_name)) % (10 ** 13)
    model_id = abs(hash(deck_name + "_model")) % (10 ** 13)

    with tempfile.TemporaryDirectory() as tmpdir:
        db_path = os.path.join(tmpdir, "collection.anki2")
        media_map: dict[str, str] = {}
        media_files: list[str] = []

        conn = sqlite3.connect(db_path)
        _create_anki_schema(conn, deck_id, deck_name, model_id)

        for i, card in enumerate(cards):
            media_idx = len(media_files)
            front = card["word"]
            back = card.get("definition", "")

            # Attach audio
            audio_path = card.get("audio_path", "")
            if audio_path and Path(audio_path).exists():
                media_map[str(media_idx)] = audio_path
                back += f'<br>[sound:{media_idx}]'
                media_files.append(audio_path)

            # Attach image
            image_path = card.get("image_path", "")
            if image_path and Path(image_path).exists():
                media_map[str(media_idx + 1)] = image_path
                back += f'<br><img src="{media_idx + 1}">'
                media_files.append(image_path)

            _insert_card(conn, deck_id, model_id, i, front, back)

        conn.commit()
        conn.close()

        # Package into .apkg (ZIP)
        with zipfile.ZipFile(str(output_path), "w") as zf:
            zf.write(db_path, "collection.anki2")
            zf.writestr("media", json.dumps(
                {str(i): Path(p).name for i, p in enumerate(media_files)}
            ))
            for i, fpath in enumerate(media_files):
                zf.write(fpath, str(i))

    return str(output_path)


def _create_anki_schema(conn: sqlite3.Connection, deck_id: int,
                         deck_name: str, model_id: int) -> None:
    """Create minimal Anki SQLite schema."""
    conn.executescript("""
        CREATE TABLE IF NOT EXISTS col (
            id INTEGER PRIMARY KEY,
            crt INTEGER NOT NULL,
            mod INTEGER NOT NULL,
            scm INTEGER NOT NULL,
            ver INTEGER NOT NULL DEFAULT 11,
            dty INTEGER NOT NULL DEFAULT 0,
            usn INTEGER NOT NULL DEFAULT -1,
            ls INTEGER NOT NULL DEFAULT 0,
            conf TEXT NOT NULL,
            models TEXT NOT NULL,
            decks TEXT NOT NULL,
            dconf TEXT NOT NULL,
            tags TEXT NOT NULL DEFAULT '{}'
        );
        CREATE TABLE IF NOT EXISTS notes (
            id INTEGER PRIMARY KEY,
            guid TEXT NOT NULL,
            mid INTEGER NOT NULL,
            mod INTEGER NOT NULL,
            usn INTEGER NOT NULL DEFAULT -1,
            tags TEXT NOT NULL DEFAULT '',
            flds TEXT NOT NULL,
            sfld TEXT NOT NULL,
            csum INTEGER NOT NULL DEFAULT 0,
            flags INTEGER NOT NULL DEFAULT 0,
            data TEXT NOT NULL DEFAULT ''
        );
        CREATE TABLE IF NOT EXISTS cards (
            id INTEGER PRIMARY KEY,
            nid INTEGER NOT NULL,
            did INTEGER NOT NULL,
            ord INTEGER NOT NULL DEFAULT 0,
            mod INTEGER NOT NULL,
            usn INTEGER NOT NULL DEFAULT -1,
            type INTEGER NOT NULL DEFAULT 0,
            queue INTEGER NOT NULL DEFAULT 0,
            due INTEGER NOT NULL DEFAULT 0,
            ivl INTEGER NOT NULL DEFAULT 0,
            factor INTEGER NOT NULL DEFAULT 0,
            reps INTEGER NOT NULL DEFAULT 0,
            lapses INTEGER NOT NULL DEFAULT 0,
            left INTEGER NOT NULL DEFAULT 0,
            odue INTEGER NOT NULL DEFAULT 0,
            odid INTEGER NOT NULL DEFAULT 0,
            flags INTEGER NOT NULL DEFAULT 0,
            data TEXT NOT NULL DEFAULT ''
        );
        CREATE TABLE IF NOT EXISTS revlog (
            id INTEGER PRIMARY KEY,
            cid INTEGER NOT NULL,
            usn INTEGER NOT NULL DEFAULT -1,
            ease INTEGER NOT NULL,
            ivl INTEGER NOT NULL,
            lastIvl INTEGER NOT NULL,
            factor INTEGER NOT NULL,
            time INTEGER NOT NULL,
            type INTEGER NOT NULL
        );
    """)

    now = int(time.time())
    model = {
        str(model_id): {
            "id": model_id, "name": deck_name, "type": 0,
            "flds": [
                {"name": "Front", "ord": 0, "sticky": False, "rtl": False, "font": "Arial", "size": 20},
                {"name": "Back",  "ord": 1, "sticky": False, "rtl": False, "font": "Arial", "size": 20},
            ],
            "tmpls": [{
                "name": "Card 1", "qfmt": "{{Front}}", "afmt": "{{FrontSide}}<hr>{{Back}}",
                "ord": 0, "bqfmt": "", "bafmt": "",
            }],
            "css": ".card { font-family: arial; font-size: 20px; text-align: center; }",
            "did": deck_id, "mod": now, "usn": -1, "sortf": 0, "req": [[0, "all", [0]]],
            "tags": [], "vers": [],
        }
    }
    deck = {
        str(deck_id): {
            "id": deck_id, "name": deck_name, "mod": now, "usn": -1,
            "lrnToday": [0, 0], "revToday": [0, 0], "newToday": [0, 0],
            "timeToday": [0, 0], "collapsed": False, "desc": "",
            "dyn": 0, "conf": 1, "extendNew": 10, "extendRev": 50,
        }
    }
    conf = json.dumps({"activeDecks": [1], "curDeck": 1, "newSpread": 0, "collapseTime": 1200, "timeLim": 0, "estTimes": True, "dueCounts": True, "curModel": None, "nextPos": 1, "sortType": "noteFld", "sortBackwards": False, "addToCur": True})
    dconf = json.dumps({"1": {"id": 1, "name": "Default", "new": {"delays": [1, 10], "ints": [1, 4, 7], "initialFactor": 2500, "order": 1, "perDay": 20}, "lapse": {"delays": [10], "mult": 0, "minInt": 1, "leechFails": 8, "leechAction": 0}, "rev": {"perDay": 100, "ease4": 1.3, "fuzz": 0.05, "minSpace": 1, "ivlFct": 1, "maxIvl": 36500}, "maxTaken": 60, "timer": 0, "autoplay": True, "replayq": True, "mod": 0, "usn": -1}})

    conn.execute(
        "INSERT INTO col VALUES (?, ?, ?, ?, 11, 0, -1, 0, ?, ?, ?, ?, '{}')",
        (1, now, now, now * 1000, conf, json.dumps(model), json.dumps(deck), dconf),
    )


def _insert_card(conn: sqlite3.Connection, deck_id: int,
                  model_id: int, idx: int, front: str, back: str) -> None:
    now = int(time.time())
    note_id = now * 1000 + idx
    card_id = note_id + 1
    guid = f"lexi_{idx:08d}"

    conn.execute(
        "INSERT INTO notes VALUES (?, ?, ?, ?, -1, '', ?, ?, 0, 0, '')",
        (note_id, guid, model_id, now, f"{front}\x1f{back}", front),
    )
    conn.execute(
        "INSERT INTO cards VALUES (?, ?, ?, 0, ?, -1, 0, 0, ?, 0, 0, 0, 0, 0, 0, 0, 0, '')",
        (card_id, note_id, deck_id, now, idx),
    )
