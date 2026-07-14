import pandas as pd
import re

#  CLEAN TEXT FUNCTION (FIX 1)
def clean_text(text):
    text = re.sub(r'[^A-Za-z0-9.,!?() \n]', ' ', text)   # remove weird chars
    text = re.sub(r'\s+', ' ', text)                     # fix spacing
    return text.strip()


# Load existing chunks
df = pd.read_csv("data/ncert_chunks.csv")

# Merge all text
text = " ".join(df["content"].astype(str).tolist())

#  APPLY CLEANING
text = clean_text(text)

#  BETTER SENTENCE SPLITTING
sentences = re.split(r'(?<=[.!?])\s+', text)

chunks = []

chunk_size = 5      # sentences per chunk
overlap = 2         #  NEW: overlap improves context continuity

for i in range(0, len(sentences), chunk_size - overlap):
    chunk_sentences = sentences[i:i + chunk_size]
    chunk = " ".join(chunk_sentences)

    #  FILTER BAD CHUNKS
    if len(chunk.split()) > 40:   # avoid too small chunks
        chunks.append(chunk.strip())


# Save back
new_df = pd.DataFrame({"content": chunks})
new_df.to_csv("data/ncert_chunks.csv", index=False)

print(" Smart chunks created:", len(chunks))
