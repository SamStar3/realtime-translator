from fastapi import FastAPI
from app.websocket import router

app = FastAPI()
app.include_router(router)
