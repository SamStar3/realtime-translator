from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from app.asr import StreamingASR
from app.translator import Translator
from app.language_map import LANG_MAP

router = APIRouter()

@router.websocket("/ws/translate")
async def translate_ws(ws: WebSocket):
    await ws.accept()
    print("🎧 Client connected")

    asr = StreamingASR()
    translator = Translator()

    target_lang = "es"  # default Spanish

    try:
        while True:
            message = await ws.receive()

            # 🎧 Audio stream
            if "bytes" in message and message["bytes"]:
                asr.add_audio(message["bytes"])

            # 📩 Control messages
            if "text" in message and message["text"]:
                text_msg = message["text"]

                # 🎯 Target language selection
                if text_msg.startswith("{"):
                    data = eval(text_msg)
                    target_lang = data.get("target_language", "es")
                    print(f"🎯 Target language set to: {target_lang}")

                # 🛑 Stop signal
                elif text_msg == "__STOP__":
                    print("🛑 Stop signal received")

                    final_text, src_lang = asr.transcribe_final()

                    if not final_text:
                        await ws.close()
                        return

                    src_code = LANG_MAP.get(src_lang, "eng_Latn")
                    tgt_code = LANG_MAP.get(target_lang, "spa_Latn")

                    translated = translator.translate(
                        final_text,
                        src_code,
                        tgt_code
                    )

                    await ws.send_json({
                        "type": "final",
                        "source_language": src_lang,
                        "target_language": target_lang,
                        "original_text": final_text,
                        "translated_text": translated
                    })

                    await ws.close()
                    print("🔌 WebSocket closed cleanly")
                    return

    except WebSocketDisconnect:
        print("❌ Client disconnected")
