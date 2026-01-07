import numpy as np
import time
from faster_whisper import WhisperModel

SAMPLE_RATE = 16000
COMMIT_WINDOW = 0.6  # seconds

class StreamingASR:
    def __init__(self):
        print("🧠 Loading Whisper model...")
        self.model = WhisperModel("small", device="cpu", compute_type="int8")
        print("✅ Whisper model loaded")

        self.buffer = bytearray()
        self.last_commit_time = 0.0
        self.segment_id = 0

    def add_audio(self, data: bytes):
        self.buffer.extend(data)

    def process(self):
        """Process buffer and yield segments"""
        min_bytes = int(SAMPLE_RATE * 2 * COMMIT_WINDOW)
        if len(self.buffer) < min_bytes:
            return []

        audio = np.frombuffer(bytes(self.buffer), dtype=np.int16).astype(np.float32) / 32768.0

        segments, info = self.model.transcribe(
            audio,
            vad_filter=False,
            temperature=0.0,
            beam_size=5
        )

        results = []
        now = time.time()

        for seg in segments:
            if now - self.last_commit_time >= COMMIT_WINDOW:
                self.segment_id += 1
                results.append({
                    "id": self.segment_id,
                    "start": seg.start,
                    "end": seg.end,
                    "text": seg.text.strip(),
                    "language": info.language
                })
                self.last_commit_time = now

        # keep small tail buffer
        self.buffer = self.buffer[-min_bytes:]

        return results
