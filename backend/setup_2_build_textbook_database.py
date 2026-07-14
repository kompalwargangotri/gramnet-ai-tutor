import pandas as pd
import faiss
import numpy as np
from sentence_transformers import SentenceTransformer
import pickle

df = pd.read_csv("data/ncert_chunks.csv")
chunks = df["content"].tolist()

print(" Loading model...")
model = SentenceTransformer("models/embeddings", local_files_only=True)

print(" Creating embeddings...")
embeddings = model.encode(
    chunks,
    normalize_embeddings=True
)

embeddings = np.array(embeddings).astype("float32")

dimension = embeddings.shape[1]
index = faiss.IndexFlatIP(dimension)

index.add(embeddings)

faiss.write_index(index, "data/faiss_index.bin")

with open("data/chunks.pkl", "wb") as f:
    pickle.dump(chunks, f)

print("✅ FAISS index created successfully!")
