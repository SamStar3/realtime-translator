from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from app.asr_streaming import StreamingASR
from app.translator import Translator
from app.language_map import LANG_MAP
import json

router = APIRouter()

@router.websocket("/ws/translate")
async def translate_ws(ws: WebSocket):
    await ws.accept()
    print("🎧 Client connected")

    asr = StreamingASR()
    translator = Translator()

    target_lang = "es"

    try:
        while True:
            msg = await ws.receive()

            # 🎯 control messages
            if "text" in msg and msg["text"]:
                if msg["text"].startswith("{"):
                    data = json.loads(msg["text"])
                    target_lang = data.get("target_language", "es")
                    print(f"🎯 Target language set to: {target_lang}")
                elif msg["text"] == "__STOP__":
                    await ws.close()
                    return

            # 🎧 audio bytes
            if "bytes" in msg and msg["bytes"]:
                asr.add_audio(msg["bytes"])
                segments = asr.process()

                for seg in segments:
                    src_code = LANG_MAP.get(seg["language"], "eng_Latn")
                    tgt_code = LANG_MAP.get(target_lang, "spa_Latn")

                    translated = translator.translate(
                        seg["text"],
                        src_code,
                        tgt_code
                    )

                    await ws.send_json({
                        "type": "segment",
                        "id": seg["id"],
                        "start": seg["start"],
                        "end": seg["end"],
                        "source_language": seg["language"],
                        "target_language": target_lang,
                        "original_text": seg["text"],
                        "translated_text": translated
                    })

    except WebSocketDisconnect:
        print("❌ Client disconnected")
