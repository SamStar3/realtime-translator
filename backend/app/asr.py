import numpy as np
import time
from faster_whisper import WhisperModel


class StreamingASR:
    def __init__(self):
        print("🧠 Loading Whisper model...")
        self.model = WhisperModel(
            "small",
            device="cpu",
            compute_type="int8"
        )
        print("✅ Whisper model loaded")

        self.buffer = bytearray()

    def add_audio(self, data: bytes):
        self.buffer.extend(data)

    def transcribe_final(self):
        MIN_BYTES = 64000  # ~2 seconds

        if len(self.buffer) < MIN_BYTES:
            return "", None

        print("📝 Transcribing full buffer...")

        audio_int16 = np.frombuffer(bytes(self.buffer), dtype=np.int16)
        audio_float32 = audio_int16.astype(np.float32) / 32768.0

        segments, info = self.model.transcribe(
            audio_float32,
            beam_size=5,
            vad_filter=False,
            temperature=0.0,
        )

        text = " ".join(seg.text.strip() for seg in segments)
        language = info.language  # ✅ THIS LINE

        print(f"📝 ASR RESULT: {text}")
        print(f"🌍 Detected language: {language}")

        self.buffer.clear()
        return text, language
