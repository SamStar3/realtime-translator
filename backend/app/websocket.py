from fastapi import APIRouter, WebSocket, WebSocketDisconnect

router = APIRouter()

@router.websocket("/ws/translate")
async def translate_ws(ws: WebSocket):
    await ws.accept()
    print("Client connected")

    try:
        while True:
            message = await ws.receive()

            if message["type"] == "websocket.disconnect":
                print("Client disconnected")
                break

            if "bytes" in message and message["bytes"] is not None:
                data = message["bytes"]
                print("Received bytes:", len(data))

    except WebSocketDisconnect:
        print("WebSocketDisconnect")

    except Exception as e:
        print("WebSocket error:", e)
