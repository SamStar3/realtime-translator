# import numpy as np
# import time
# from faster_whisper import WhisperModel

# SAMPLE_RATE = 16000
# PARTIAL_SEC = 0.6  # latency control

# class StreamingASR:
#     def __init__(self):
#         self.model = WhisperModel(
#             "small",
#             device="cpu",
#             compute_type="int8"
#         )
#         self.buffer = bytearray()
#         self.last_partial = time.time()

#     def add_audio(self, data: bytes):
#         self.buffer.extend(data)

#     def _decode(self, audio):
#         segments, info = self.model.transcribe(
#             audio,
#             beam_size=5,
#             vad_filter=False,
#             temperature=0.0
#         )
#         text = " ".join(s.text.strip() for s in segments)
#         return text.strip(), info.language

#     def partial_ready(self):
#         return time.time() - self.last_partial >= PARTIAL_SEC

#     def transcribe_partial(self):
#         if len(self.buffer) < SAMPLE_RATE * 2:
#             return "", None

#         audio = np.frombuffer(
#             self.buffer[-int(SAMPLE_RATE*PARTIAL_SEC*2):],
#             dtype=np.int16
#         ).astype(np.float32) / 32768.0

#         self.last_partial = time.time()
#         return self._decode(audio)

#     def transcribe_final(self):
#         audio = np.frombuffer(
#             self.buffer, dtype=np.int16
#         ).astype(np.float32) / 32768.0

#         text, lang = self._decode(audio)
#         self.buffer.clear()
#         return text, lang
