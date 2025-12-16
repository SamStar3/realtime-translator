from fastapi import APIRouter, WebSocket, WebSocketDisconnect

router = APIRouter()

@router.websocket("/ws/translate")
async def translate_ws(ws: WebSocket):
    await ws.accept()
    print("Client connected")

    try:
        while True:
            message = await ws.receive()

            # Handle text messages
            if "text" in message:
                text = message["text"]
                print("Received text:", text)
                await ws.send_text(f"Echo: {text}")

            # Handle binary messages (audio later)
            elif "bytes" in message:
                data = message["bytes"]
                print("Received bytes:", len(data))
                await ws.send_text(f"Received {len(data)} bytes")

    except WebSocketDisconnect:
        print("Client disconnected")
