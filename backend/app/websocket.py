from fastapi import APIRouter, WebSocket
from app.asr_streaming import StreamingASR
import asyncio

router = APIRouter()

@router.websocket("/ws/translate")
async def ws_translate(ws: WebSocket):
    await ws.accept()
    print("🎧 Client connected")

    asr = StreamingASR()

    task = asyncio.create_task(asr.process(ws))

    try:
        while True:
            msg = await ws.receive()

            if "bytes" in msg:
                asr.add_audio(msg["bytes"])

            if "text" in msg and msg["text"] == "__STOP__":
                break

    except Exception as e:
        print("WS error:", e)

    finally:
        task.cancel()
        await ws.close()
        print("🔌 Closed")
