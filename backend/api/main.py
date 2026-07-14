from fastapi import FastAPI
from pydantic import BaseModel
from core.tutor import tutor_response
from core.search_engine import load_index

app = FastAPI(title="AI Tutor Backend")

# Load FAISS index + chunks
index, chunks = load_index()

class Query(BaseModel):
    text: str
    query: str = None # fallback

@app.post("/predict")
def predict(data: Query):
    text = data.query if data.query else data.text
    response = tutor_response(text, chunks, index)
    return {"answer": response}

@app.post("/ask")
def ask(data: Query):
    text = data.query if data.query else data.text
    response = tutor_response(text, chunks, index)
    return {"answer": response}

@app.get("/")
def home():
    return {"status": "AI Tutor Backend Running 🚀"}

@app.get("/health")
def health():
    return {"status": "ok"}
