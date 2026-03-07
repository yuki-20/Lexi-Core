"""
LexiCore — FastAPI Router
===========================
All 7 PRD endpoints + learning/streak endpoints.
"""

from __future__ import annotations

import asyncio
import time
from typing import Any

from fastapi import APIRouter, Query, HTTPException
from pydantic import BaseModel

router = APIRouter(prefix="/api", tags=["engine"])


# ── Request / Response Models ─────────────────────────────────────────

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


# ── Dependency — engine state is injected via app.state ───────────────

def _engine(request):
    """Access the shared engine instance from app state."""
    return request.app.state.engine


# ── 1. Exact Search ───────────────────────────────────────────────────

@router.get("/search")
async def search_exact(q: str = Query(..., min_length=1), request: Any = None):
    from fastapi import Request
    # This is handled via the function parameter binding in FastAPI
    pass


@router.get("/search")
async def search_exact(q: str = Query(..., min_length=1)):
    """Engine.search_exact(query) → definition dict."""
    # Actual implementation is done in main.py where engine is available
    # This file defines route structure; main.py mounts them with engine context
    pass


# We'll use a functional approach — routes are registered in main.py
# with direct access to the engine singleton.
