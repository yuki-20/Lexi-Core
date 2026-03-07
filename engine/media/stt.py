"""
LexiCore — Speech-to-Text (Vosk)
=================================
Captures microphone input and converts to text for search queries.
Requires a Vosk language model to be downloaded separately.
"""

from __future__ import annotations

# Stub — full implementation requires PyAudio + Vosk model download.
# This provides the interface for the API layer.


def recognize_speech(timeout_seconds: float = 5.0) -> str | None:
    """Capture mic input and return recognized text, or None on failure.

    Note: Requires ``vosk`` and ``pyaudio`` to be installed, plus a
    Vosk language model at ``data/vosk-model-small-en-us-0.15/``.
    """
    try:
        import json
        import pyaudio
        from vosk import Model, KaldiRecognizer

        model_path = "data/vosk-model-small-en-us-0.15"
        model = Model(model_path)
        rec = KaldiRecognizer(model, 16000)

        pa = pyaudio.PyAudio()
        stream = pa.open(
            format=pyaudio.paInt16,
            channels=1,
            rate=16000,
            input=True,
            frames_per_buffer=8000,
        )
        stream.start_stream()

        import time
        start = time.time()
        while time.time() - start < timeout_seconds:
            data = stream.read(4000, exception_on_overflow=False)
            if rec.AcceptWaveform(data):
                result = json.loads(rec.Result())
                text = result.get("text", "").strip()
                if text:
                    stream.stop_stream()
                    stream.close()
                    pa.terminate()
                    return text

        # Final result
        result = json.loads(rec.FinalResult())
        stream.stop_stream()
        stream.close()
        pa.terminate()
        return result.get("text", "").strip() or None

    except Exception:
        return None
