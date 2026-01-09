# # app/streaming_asr.py
# import numpy as np
# import time
# from faster_whisper import WhisperModel

# SAMPLE_RATE = 16000
# WINDOW_SEC = 1.0          # sliding window
# STEP_SEC = 0.5            # update every 500ms

# class StreamingASR:
#     def __init__(self):
#         self.model = WhisperModel(
#             "small",
#             device="cpu",
#             compute_type="int8"
#         )

#         self.audio_buffer = np.zeros(0, dtype=np.float32)
#         self.last_emit_time = 0.0
#         self.seen_segments = set()

#     def add_audio(self, pcm_bytes: bytes):
#         audio = np.frombuffer(pcm_bytes, dtype=np.int16).astype(np.float32)
#         audio /= 32768.0
#         self.audio_buffer = np.concatenate([self.audio_buffer, audio])

#         max_samples = int(SAMPLE_RATE * 10)
#         if len(self.audio_buffer) > max_samples:
#             self.audio_buffer = self.audio_buffer[-max_samples:]

#     def process(self):
#         if len(self.audio_buffer) < SAMPLE_RATE * WINDOW_SEC:
#             return []

#         segments, info = self.model.transcribe(
#             self.audio_buffer[-int(SAMPLE_RATE * WINDOW_SEC):],
#             vad_filter=True,
#             temperature=0.0,
#             beam_size=5
#         )

#         new_segments = []
#         for seg in segments:
#             key = (round(seg.start, 2), seg.text.strip())
#             if key not in self.seen_segments:
#                 self.seen_segments.add(key)
#                 new_segments.append({
#                     "text": seg.text.strip(),
#                     "start": seg.start,
#                     "end": seg.end,
#                     "language": info.language
#                 })

#         return new_segments
