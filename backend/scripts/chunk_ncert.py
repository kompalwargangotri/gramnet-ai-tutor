import fitz  # PyMuPDF
import pandas as pd
import os
from pathlib import Path

# -------------------------------
# CONFIG
# -------------------------------
BACKEND_DIR = Path(__file__).resolve().parent.parent
PDF_FOLDER = BACKEND_DIR / "data" / "ncert_books"
OUTPUT_FILE = BACKEND_DIR / "data" / "ncert_chunks.csv"

CHUNK_SIZE = 400
OVERLAP = 50


# -------------------------------
# CLEAN TEXT
# -------------------------------
def clean_text(text):
    text = text.replace("\n", " ")
    text = text.replace("  ", " ")
    return text.strip()


# -------------------------------
# CHUNKING FUNCTION
# -------------------------------
def chunk_text(text, chunk_size=400, overlap=50):
    words = text.split()
    chunks = []

    for i in range(0, len(words), chunk_size - overlap):
        chunk = " ".join(words[i:i + chunk_size])
        if len(chunk) > 50:
            chunks.append(chunk)

    return chunks


# -------------------------------
# EXTRACT TEXT FROM PDF
# -------------------------------
def extract_pdf_chunks(pdf_path):
    print(f"\n📄 Opening: {pdf_path}")

    doc = fitz.open(pdf_path)
    all_text = ""

    for i, page in enumerate(doc):
        text = page.get_text("text")
        print(f"Page {i} length:", len(text))
        all_text += text

    all_text = clean_text(all_text)

    print("Total text length:", len(all_text))

    chunks = chunk_text(all_text)

    print("Number of chunks:", len(chunks))

    return chunks


# -------------------------------
# MAIN FUNCTION
# -------------------------------
def main():
    data = []
    chunk_id = 0

    print("📂 Scanning folders for PDFs...")

    all_pdf_files = []

    # 🔥 WALK THROUGH ALL FOLDERS
    for root, dirs, files in os.walk(PDF_FOLDER):
        for file in files:
            if file.lower().endswith(".pdf"):
                full_path = os.path.join(root, file)
                all_pdf_files.append(full_path)

    print("\n📄 PDF files found:")
    for f in all_pdf_files:
        print(f)

    if len(all_pdf_files) == 0:
        print("\n❌ No PDF files found. Check folder structure.")
        return

    # 🔥 PROCESS EACH PDF
    for pdf_path in all_pdf_files:
        print(f"\n🚀 Processing: {pdf_path}")

        chunks = extract_pdf_chunks(pdf_path)

        for chunk in chunks:
            data.append({
                "id": chunk_id,
                "source": os.path.basename(pdf_path),
                "content": chunk
            })
            chunk_id += 1

    df = pd.DataFrame(data)

    if len(df) == 0:
        print("\n❌ ERROR: No chunks created. Check text extraction.")
    else:
        df.to_csv(OUTPUT_FILE, index=False)
        print(f"\n✅ SUCCESS: Saved {len(df)} chunks to {OUTPUT_FILE}")


# -------------------------------
# RUN
# -------------------------------
if __name__ == "__main__":
    main()
