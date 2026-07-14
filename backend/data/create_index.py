import pandas as pd
import numpy as np
import faiss
from sentence_transformers import SentenceTransformer

# Load data
df = pd.read_csv("data/ncert_chunks.csv")
chunks = df["content"].tolist()

# Load model
model = SentenceTransformer('all-MiniLM-L6-v2')

print(" Encoding chunks...")
embeddings = model.encode(chunks)

# Convert to numpy
embeddings = np.array(embeddings).astype("float32")

# Create FAISS index
dim = embeddings.shape[1]
index = faiss.IndexFlatL2(dim)

index.add(embeddings)

# Save index + embeddings
faiss.write_index(index, "data/faiss_index.bin")
np.save("data/embeddings.npy", embeddings)

print(" FAISS index created and saved!")
