"""
LexiCore — OCR Screen Grab (Tesseract)
========================================
Captures a screen region and extracts text via Tesseract OCR.
"""

from __future__ import annotations

from typing import Any


def ocr_screen_region(x1: int, y1: int, x2: int, y2: int) -> dict[str, Any]:
    """Capture a bounding box from the screen and OCR it.

    Returns dict with 'text' (extracted string) and 'confidence' (float 0-1).
    """
    try:
        from PIL import ImageGrab
        import pytesseract

        # Capture screen region
        screenshot = ImageGrab.grab(bbox=(x1, y1, x2, y2))

        # OCR
        data = pytesseract.image_to_data(screenshot, output_type=pytesseract.Output.DICT)
        texts = [t.strip() for t in data.get("text", []) if t.strip()]
        confidences = [
            float(c) for c in data.get("conf", [])
            if str(c).replace("-", "").isdigit() and int(c) > 0
        ]

        text = " ".join(texts)
        avg_conf = sum(confidences) / len(confidences) / 100.0 if confidences else 0.0

        return {"text": text, "confidence": round(avg_conf, 2)}

    except Exception as e:
        return {"text": "", "confidence": 0.0, "error": str(e)}
