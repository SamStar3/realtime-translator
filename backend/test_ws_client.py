import asyncio
import websockets
import os

async def test_ws():
    uri = "ws://127.0.0.1:8000/ws/translate"

    async with websockets.connect(uri) as websocket:
        print("Connected to server")

        while True:
            cmd = input("Type 'send' to send binary, 'exit' to quit: ")

            if cmd == "exit":
                break

            if cmd == "send":
                fake_audio = os.urandom(320)  # simulate ~20ms audio
                await websocket.send(fake_audio)

                response = await websocket.recv()
                print("Server:", response)

asyncio.run(test_ws())
