from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from app.asr import StreamingASR

router = APIRouter()


@router.websocket("/ws/translate")
async def translate_ws(ws: WebSocket):
    await ws.accept()
    print("🎧 Client connected")

    asr = StreamingASR()

    try:
        while True:
            message = await ws.receive()

            if message["type"] == "websocket.receive":

                if "bytes" in message and message["bytes"]:
                    asr.add_audio(message["bytes"])

                if "text" in message and message["text"] == "__STOP__":
                    print("🛑 Stop signal received")

                    final_text, language = asr.transcribe_final()

                    await ws.send_json({
                        "type": "final",
                        "text": final_text,
                        "language": language
                    })

                    await ws.close(code=1000)
                    return

    except WebSocketDisconnect:
        print("❌ Client disconnected")
