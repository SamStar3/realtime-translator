from fastapi import FastAPI
from app.websocket import router as ws_router

app = FastAPI(title="Real-Time Translator")

app.include_router(ws_router)

@app.get("/")
def health():
    return {"status": "ok"}
