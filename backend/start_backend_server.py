import os
import sys

# Ensure current working directory is backend for index and model paths
backend_dir = os.path.dirname(os.path.abspath(__file__))
os.chdir(backend_dir)
sys.path.append(backend_dir)

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from core.tutor import tutor_response
from core.retriever import retrieve
from core.search_engine import load_index
from langdetect import detect
from core.translator import to_english, to_original
import json
import random
import os
import csv
from datetime import datetime

app = FastAPI()

# Enable CORS for Flutter Web
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load FAISS index + chunks
index, chunks = load_index()

class AskRequest(BaseModel):
    query: str
    lang: str = "en"
    difficulty: str = "easy"

@app.get("/")
def home():
    return {"status": "AI Tutor Running"}

@app.get("/health")
def health():
    return {"status": "ok"}


def is_hindi_or_hinglish(query: str) -> bool:
    # Check for Devanagari characters (used in Hindi and Marathi script)
    if any(ord(char) >= 0x0900 and ord(char) <= 0x097F for char in query):
        return True

    hinglish_keywords = {
        'kya', 'kaise', 'kab', 'kise', 'kyu', 'kyon', 'hai', 'hain', 'he',
        'hota', 'hoti', 'hote', 'karta', 'karti', 'karne', 'se', 'ko',
        'mein', 'me', 'par', 'pe', 'bhi', 'aur', 'ya', 'kya-hai', 'samjhao',
        'batao', 'bataiye', 'ki', 'ke', 'ka', 'ko', 'se', 'tha', 'thi', 'the',
        'kuch', 'hoga', 'hogi', 'hogya'
    }

    import re
    words = re.findall(r'\b\w+\b', query.lower())
    for w in words:
        if w in hinglish_keywords:
            return True
    return False

@app.post("/ask")
def ask(data: AskRequest):
    with open("backend_debug.log", "a", encoding="utf-8") as log:
        log.write(f"\n--- New Request ---\n")
        log.write(f"Query: {data.query}\n")
        log.write(f"Client Lang: {data.lang}\n")

        # Determine response language:
        # 1. Start with client dropdown selection
        detected_lang = data.lang

        # 2. Override if Devanagari script is present (must be Hindi or Marathi)
        if any(ord(char) >= 0x0900 and ord(char) <= 0x097F for char in data.query):
            try:
                lang_det = detect(data.query)
                if lang_det in ["hi", "mr"]:
                    detected_lang = lang_det
                else:
                    detected_lang = "hi"
            except:
                detected_lang = "hi"
        # 3. If no Devanagari is present, and client selected English, keep it strictly English
        elif data.lang == "en":
            detected_lang = "en"

        log.write(f"Detected Lang: {detected_lang}\n")

        query_en = to_english(data.query, detected_lang)
        log.write(f"Translated Query: {query_en}\n")

        answer_en = tutor_response(query_en, chunks, index)

        if not answer_en.strip() or answer_en.strip().lower() == "i don't know":
            log.write(f"Result: No Context Found\n")
            answer_en = "I don't know the answer based on the provided textbook."
        else:
            log.write(f"AI Answer (EN): {answer_en[:100]}\n")

        final_answer = to_original(answer_en, detected_lang)
        log.write(f"Final Answer: {final_answer[:100]}\n")

    return {"answer": final_answer, "detected_lang": detected_lang}

from core.llm_engine import generate_answer
import json
import csv
import random
import os

class QuizRequest(BaseModel):
    lang: str = "en"
    subject: str = "Science"
    class_level: str = "10"
    difficulty: str = "easy"
    topic: str = "General"
    asked: list[str] = []

@app.get("/topics")
def get_topics(lang: str, subject: str, class_level: str):
    file_path = "quiz_engine/quiz_database.csv"
    if not os.path.exists(file_path):
        return {"topics": ["General"]}

    topics = set()
    with open(file_path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row["subject"].strip().lower() == subject.strip().lower() and \
               str(row["class"]).strip() == str(class_level).strip() and \
               row["lang"].strip().lower() == lang.strip().lower():
                topics.add(row.get("topic", "General"))

    # Sort and ensure "General" is present
    sorted_topics = sorted(list(topics))
    return {"topics": sorted_topics if sorted_topics else ["General"]}

@app.post("/quiz")
def get_quiz(data: QuizRequest):
    file_path = "quiz_engine/quiz_database.csv"
    if not os.path.exists(file_path):
        return {"error": "Quiz database not found in quiz_engine folder."}

    valid_questions = []
    with open(file_path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row["subject"].strip().lower() == data.subject.strip().lower() and \
               str(row["class"]).strip() == str(data.class_level).strip() and \
               row["difficulty"].strip().lower() == data.difficulty.strip().lower() and \
               row["lang"].strip().lower() == data.lang.strip().lower() and \
               row.get("topic", "General").strip().lower() == data.topic.strip().lower() and \
               row["question"] not in data.asked:
                valid_questions.append(row)

    # Fallback to any difficulty if specific one not found (still filtering asked)
    if not valid_questions:
        with open(file_path, "r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for row in reader:
                if row["subject"].strip().lower() == data.subject.strip().lower() and \
                   str(row["class"]).strip() == str(data.class_level).strip() and \
                   row["lang"].strip().lower() == data.lang.strip().lower() and \
                   row["question"] not in data.asked:
                    valid_questions.append(row)

    # IF NO QUESTIONS IN CSV, USE LOCAL LLM FALLBACK
    if not valid_questions:
        try:
            # Advanced topic mapping for high-quality AI generation
            standard_topics = {
                "6": {"Math": "Fractions and Decimals", "Science": "Components of Food", "English": "Nouns and Pronouns"},
                "7": {"Math": "Integers and Ratios", "Science": "Nutrition in Plants", "English": "Tenses and Verbs"},
                "8": {"Math": "Rational Numbers and Squares", "Science": "Microorganisms", "English": "Active and Passive Voice"},
                "9": {"Math": "Polynomials and Geometry", "Science": "Matter and Atoms", "English": "Reported Speech"},
                "10": {"Math": "Trigonometry and Quadratic Equations", "Science": "Electricity and Carbon Compounds", "English": "Complex Sentence Synthesis"}
            }

            topic = standard_topics.get(data.class_level, {}).get(data.subject, "General Education")

            prompt = f"""<|system|>
            You are an expert NCERT teacher. Generate a {data.difficulty} MCQ for Class {data.class_level} students in {data.lang} about {topic}.
            The question must be high quality and appropriate for the standard level.
            Return ONLY a valid JSON object.</s>
            <|user|>
            Create a JSON quiz object with "question", "options" (list of 4), and "answer_index" (0-3).</s>
            <|assistant|>
            """
            response_text = generate_answer(prompt)
            # Clean response text
            start = response_text.find('{')
            end = response_text.rfind('}') + 1
            if start != -1 and end != -1:
                quiz_data = json.loads(response_text[start:end])
                quiz_data["difficulty"] = data.difficulty
                quiz_data["lang"] = data.lang
                return quiz_data
        except Exception as e:
            return {"error": f"No questions found and AI fallback failed: {str(e)}"}

    q = random.choice(valid_questions)
    question = q["question"]
    options = [q["option1"], q["option2"], q["option3"], q["option4"]]
    answer = q["answer"]
    try:
        answer_index = options.index(answer)
    except:
        answer_index = 0

    return {
        "question": question,
        "options": options,
        "answer_index": answer_index,
        "difficulty": q["difficulty"],
        "lang": data.lang
    }

@app.get("/flashcards")
def get_flashcards():
    # Use AI to generate meaningful facts from random diverse chunks
    try:
        sample_chunks = random.sample(chunks, min(len(chunks), 20))
        context = "\n".join(sample_chunks)
        prompt = f"""<|system|>
        Extract 5 important educational facts (definitions or scientific laws) from the context. Return ONLY a JSON list of strings.</s>
        <|user|>
        Context: {context}</s>
        <|assistant|>
        """
        response_text = generate_answer(prompt)
        # Find the JSON list
        start = response_text.find('[')
        end = response_text.rfind(']') + 1
        if start != -1 and end != -1:
            facts = json.loads(response_text[start:end])
            return {"flashcards": facts}
    except:
        pass

    # Static fallbacks if AI fails or context is poor
    return {"flashcards": [
        "Photosynthesis is the process by which green plants turn carbon dioxide and water into food using sunlight.",
        "Newton's First Law of Motion states that an object at rest stays at rest unless acted upon by an external force.",
        "The Pythagoras Theorem states that in a right-angled triangle, a² + b² = c².",
        "A proper noun always starts with a capital letter and refers to a specific name, place or organization.",
        "The power house of the cell is called the Mitochondria."
    ]}

NCERT_SYLLABUS = {
    "Science": {
        "6": [
            "Components of Food",
            "Sorting Materials into Groups",
            "Separation of Substances",
            "Getting to Know Plants",
            "Body Movements",
            "The Living Organisms and their Surroundings",
            "Motion and Measurement of Distances",
            "Light, Shadows and Reflections",
            "Electricity and Circuits",
            "Fun with Magnets"
        ],
        "7": [
            "Nutrition in Plants",
            "Nutrition in Animals",
            "Heat",
            "Acids, Bases and Salts",
            "Physical and Chemical Changes",
            "Respiration in Organisms",
            "Transportation in Animals and Plants",
            "Reproduction in Plants",
            "Motion and Time",
            "Electric Current and its Effects",
            "Light"
        ],
        "8": [
            "Crop Production and Management",
            "Microorganisms: Friend and Foe",
            "Coal and Petroleum",
            "Combustion and Flame",
            "Conservation of Plants and Animals",
            "Reproduction in Animals",
            "Reaching the Age of Adolescence",
            "Force and Pressure",
            "Friction",
            "Sound",
            "Chemical Effects of Electric Current",
            "Some Natural Phenomena",
            "Light"
        ],
        "9": [
            "Matter in Our Surroundings",
            "Is Matter Around Us Pure",
            "Atoms and Molecules",
            "Structure of the Atom",
            "The Fundamental Unit of Life",
            "Tissues",
            "Motion",
            "Force and Laws of Motion",
            "Gravitation",
            "Work and Energy",
            "Sound",
            "Improvement in Food Resources"
        ],
        "10": [
            "Chemical Reactions and Equations",
            "Acids, Bases and Salts",
            "Metals and Non-metals",
            "Carbon and its Compounds",
            "Life Processes",
            "Control and Coordination",
            "How do Organisms Reproduce?",
            "Heredity",
            "Light – Reflection and Refraction",
            "The Human Eye and the Colorful World",
            "Electricity",
            "Magnetic Effects of Electric Current",
            "Our Environment"
        ]
    },
    "Math": {
        "6": [
            "Knowing Our Numbers",
            "Whole Numbers",
            "Playing with Numbers",
            "Basic Geometrical Ideas",
            "Understanding Elementary Shapes",
            "Integers",
            "Fractions",
            "Decimals",
            "Data Handling",
            "Mensuration",
            "Algebra",
            "Ratio and Proportion"
        ],
        "7": [
            "Integers",
            "Fractions and Decimals",
            "Data Handling",
            "Simple Equations",
            "Lines and Angles",
            "The Triangle and its Properties",
            "Comparing Quantities",
            "Rational Numbers",
            "Perimeter and Area",
            "Algebraic Expressions",
            "Exponents and Powers",
            "Symmetry"
        ],
        "8": [
            "Rational Numbers",
            "Linear Equations in One Variable",
            "Understanding Quadrilaterals",
            "Data Handling",
            "Squares and Square Roots",
            "Cubes and Cube Roots",
            "Comparing Quantities",
            "Algebraic Expressions and Identities",
            "Mensuration",
            "Exponents and Powers",
            "Direct and Inverse Proportions",
            "Factorisation",
            "Introduction to Graphs"
        ],
        "9": [
            "Number Systems",
            "Polynomials",
            "Coordinate Geometry",
            "Linear Equations in Two Variables",
            "Introduction to Euclid’s Geometry",
            "Lines and Angles",
            "Triangles",
            "Quadrilaterals",
            "Circles",
            "Heron’s Formula",
            "Surface Areas and Volumes",
            "Statistics"
        ],
        "10": [
            "Real Numbers",
            "Polynomials",
            "Pair of Linear Equations in Two Variables",
            "Quadratic Equations",
            "Arithmetic Progressions",
            "Triangles",
            "Coordinate Geometry",
            "Introduction to Trigonometry",
            "Some Applications of Trigonometry",
            "Circles",
            "Areas Related to Circles",
            "Surface Areas and Volumes",
            "Statistics",
            "Probability"
        ]
    },
    "English": {
        "6": [
            "Who Did Patrick's Homework?",
            "How the Dog Found Himself a New Master!",
            "Taro's Reward",
            "An Indian-American Woman in Space: Kalpana Chawla",
            "A Different Kind of School",
            "Who I Am",
            "Fair Play",
            "A Game of Chance",
            "Desert Animals",
            "The Banyan Tree"
        ],
        "7": [
            "Three Questions",
            "A Gift of Chappals",
            "Gopal and the Hilsa Fish",
            "The Ashes That Made Trees Bloom",
            "Quality",
            "Expert Detectives",
            "The Invention of Vita-Wonk",
            "Fire: Friend and Foe",
            "A Bicycle in Good Repair",
            "The Story of Cricket"
        ],
        "8": [
            "The Best Christmas Present in the World",
            "The Tsunami",
            "Glimpses of the Past",
            "Bepin Choudhury's Lapse of Memory",
            "The Summit Within",
            "This is Jody's Fawn",
            "A Visit to Cambridge",
            "A Short Monsoon Diary",
            "The Great Stone Face"
        ],
        "9": [
            "The Fun They Had",
            "The Sound of Music",
            "The Little Girl",
            "A Truly Beautiful Mind",
            "The Snake and the Mirror",
            "My Childhood",
            "Reach for the Top",
            "Kathmandu",
            "If I Were You"
        ],
        "10": [
            "A Letter to God",
            "Nelson Mandela: Long Walk to Freedom",
            "Two Stories about Flying",
            "From the Diary of Anne Frank",
            "Glimpses of India",
            "Mijbil the Otter",
            "Madam Rides the Bus",
            "The Sermon at Benares",
            "The Proposal"
        ]
    }
}

@app.get("/download_library")
def download_library():
    # Return mapping of book title to empty list
    books = {}
    for subject, classes in NCERT_SYLLABUS.items():
        for class_level, chapters in classes.items():
            for i, ch_name in enumerate(chapters, 1):
                title = f"NCERT {subject} Class {class_level} - Chapter {i}: {ch_name}"
                books[title] = []
    return books

def translate_markdown(markdown_text: str, lang: str) -> str:
    if lang == "en":
        return markdown_text

    from core.translator import is_online
    online = is_online()

    paragraphs = markdown_text.split("\n\n")
    translated_paragraphs = []

    for p in paragraphs:
        p_stripped = p.strip()
        if not p_stripped:
            translated_paragraphs.append("")
            continue
        if p_stripped == "---":
            translated_paragraphs.append("---")
            continue

        lines = p.split("\n")
        translated_lines = []
        current_group = []

        def flush_group():
            if not current_group:
                return
            text_to_translate = " ".join(current_group)
            translated_text = to_original(text_to_translate, lang, online=online)
            translated_lines.append(translated_text)
            current_group.clear()

        for line in lines:
            line_stripped = line.strip()
            if not line_stripped:
                flush_group()
                translated_lines.append("")
                continue
            if line_stripped == "---":
                flush_group()
                translated_lines.append("---")
                continue
            if line_stripped.startswith("**[Page"):
                flush_group()
                translated_lines.append(line_stripped)
                continue

            # Check if it's a Markdown header (starts with #)
            if line_stripped.startswith("#"):
                flush_group()
                num_hashes = 0
                for char in line_stripped:
                    if char == '#':
                        num_hashes += 1
                    else:
                        break

                rest = line_stripped[num_hashes:].strip()
                # Extract any emoji prefix
                emoji_prefix = ""
                for emoji in ["🎯", "📖", "✍️", "📝", "❓"]:
                    if rest.startswith(emoji):
                        emoji_prefix = emoji + " "
                        rest = rest[len(emoji):].strip()
                        break

                translated_text = to_original(rest, lang, online=online)
                reconstructed = f"{'#' * num_hashes} {emoji_prefix}{translated_text}"
                translated_lines.append(reconstructed)
            elif line_stripped.startswith("* "):
                flush_group()
                rest = line_stripped[2:].strip()
                translated_text = to_original(rest, lang, online=online)
                translated_lines.append(f"* {translated_text}")
            elif line_stripped.startswith("- "):
                flush_group()
                rest = line_stripped[2:].strip()
                translated_text = to_original(rest, lang, online=online)
                translated_lines.append(f"- {translated_text}")
            else:
                current_group.append(line_stripped)

        flush_group()
        translated_paragraphs.append("\n".join(translated_lines))

    return "\n\n".join(translated_paragraphs)

import fitz

def find_pdf_path(class_level: str, subject: str, chapter_num: int) -> str:
    base_dir = "data/ncert_books"
    if not os.path.exists(base_dir):
        return None

    subject_clean = subject.lower().strip()
    class_clean = class_level.strip()

    # Identify target folder names
    target_folders = []
    for entry in os.listdir(base_dir):
        entry_path = os.path.join(base_dir, entry)
        if os.path.isdir(entry_path):
            folder_name = entry.lower()
            if f"class{class_clean}" in folder_name and subject_clean in folder_name:
                target_folders.append(entry_path)

    # Search within the matching folders
    chapter_suffix = f"{chapter_num:02d}.pdf"
    for folder in target_folders:
        for file in os.listdir(folder):
            if file.lower().endswith(chapter_suffix):
                return os.path.join(folder, file)
    return None

def is_boilerplate(line: str, subject: str) -> bool:
    import re
    stripped = line.strip()
    if not stripped:
        return False
    # Check for reprint/rationalisation notes
    if re.search(r'Reprint \d{4}', stripped, re.I) or re.search(r'Rationali[sz]ed', stripped, re.I):
        return True
    # Check if it's exactly a page number
    if stripped.isdigit():
        return True
    # Check for subject name or common headers
    if stripped.lower() in (subject.lower(), "science", "mathematics", "english"):
        return True
    if "reprint" in stripped.lower():
        return True
    return False

def clean_and_merge_lines(raw_text: str, subject: str) -> list:
    import re
    # Remove soft hyphens split across lines
    raw_text = raw_text.replace("-\n", "")

    lines = raw_text.split("\n")
    filtered = []
    for line in lines:
        if not is_boilerplate(line, subject):
            filtered.append(line)

    if not filtered:
        return []

    # Reconstruct headings and layout fragments using overlap merger
    processed = []
    current = filtered[0].strip()

    for next_line in filtered[1:]:
        next_line = next_line.strip()
        if not next_line:
            if current:
                processed.append(current)
                current = ""
            processed.append("")
            continue

        # Drop caps fix
        if len(current) == 1 and current.isupper() and next_line and next_line[0].islower():
            current = current + next_line
            continue

        # Substring de-duplication
        if next_line in current:
            continue
        if current in next_line:
            current = next_line
            continue

        # Merge overlapping strings (minimum 3 overlap chars)
        merged = False
        max_overlap = min(len(current), len(next_line))
        for i in range(max_overlap, 2, -1):
            suffix = current[-i:]
            prefix = next_line[:i]
            if suffix == prefix:
                current = current + next_line[i:]
                merged = True
                break

        if not merged:
            if current:
                processed.append(current)
            current = next_line

    if current:
        processed.append(current)

    # Fix bullets
    i = 0
    while i < len(processed):
        line = processed[i].strip()
        if line in ("n", "o", "•", "–"):
            j = i + 1
            while j < len(processed) and not processed[j].strip():
                j += 1
            if j < len(processed):
                next_line = processed[j].strip()
                if not (next_line.startswith("* ") or next_line.startswith("- ")):
                    processed[j] = f"* {next_line}"
                processed[i] = ""
        i += 1

    # Filter empty elements but keep formatting paragraphs
    final_lines = []
    for line in processed:
        cleaned = re.sub(r'\s+', ' ', line).strip()
        if cleaned:
            final_lines.append(cleaned)
        elif not final_lines or final_lines[-1] != "":
            final_lines.append("")

    return final_lines

def extract_chapter_markdown(pdf_path: str, subject: str, chapter_name: str) -> str:
    doc = fitz.open(pdf_path)
    content_lines = []

    content_lines.append(f"# {chapter_name}")
    content_lines.append("---")
    content_lines.append("### 📖 Authentic NCERT Textbook Lesson")
    content_lines.append("")

    for page_num, page in enumerate(doc, 1):
        text = page.get_text("text")
        if text:
            cleaned_lines = clean_and_merge_lines(text, subject)
            page_text = "\n".join(cleaned_lines).strip()
            if page_text and not page_text.isdigit():
                content_lines.append(f"**[Page {page_num}]**")
                content_lines.append(page_text)
                content_lines.append("")

    return "\n".join(content_lines)

@app.get("/download_book")
def download_book(title: str, lang: str = "en"):
    # Parse Class, Subject, and Chapter Name
    subject = "Science"
    class_level = "10"
    chapter_name = "General"
    chapter_num = 1

    try:
        parts = title.split(" - ")
        if len(parts) >= 2:
            left = parts[0]
            right = parts[1]

            left_parts = left.split(" ")
            if len(left_parts) >= 4:
                subject = left_parts[1]
                class_level = left_parts[3]

            right_parts = right.split(": ")
            if len(right_parts) >= 2:
                chapter_name = right_parts[1]
            else:
                chapter_name = right

            if "chapter" in right_parts[0].lower():
                num_str = right_parts[0].lower().replace("chapter", "").strip()
                chapter_num = int(num_str)
    except Exception as e:
        print(f"Error parsing title: {e}")

    # OPTION 2: Actual NCERT Textbook Chapter Serving (Syllabus Aligned)
    processed_dir = "data/ncert_processed"
    filename = f"class{class_level}_{subject.lower()}_chapter{chapter_num:02d}.md"
    processed_path = os.path.join(processed_dir, f"class{class_level}_{subject.lower()}", filename)

    chapter_content = ""
    if os.path.exists(processed_path):
        print(f"Serving pre-processed authentic NCERT textbook chapter from: {processed_path}")
        with open(processed_path, "r", encoding="utf-8") as f:
            chapter_content = f.read()
    else:
        pdf_path = find_pdf_path(class_level, subject, chapter_num)
        if pdf_path and os.path.exists(pdf_path):
            print(f"Serving authentic NCERT textbook chapter by extracting on-the-fly from: {pdf_path}")
            chapter_content = extract_chapter_markdown(pdf_path, subject, chapter_name)
            # Cache it
            try:
                os.makedirs(os.path.dirname(processed_path), exist_ok=True)
                with open(processed_path, "w", encoding="utf-8") as f:
                    f.write(chapter_content)
            except Exception as cache_err:
                print(f"Failed to cache extracted chapter: {cache_err}")
        else:
            # ONLY Option 2: No LLM fallback. Return warning message.
            print(f"Textbook file not found for Class {class_level} {subject} Chapter {chapter_num}.")
            chapter_content = f"""# {chapter_name}
---
### ⚠️ Official NCERT Textbook Missing
Sorry, the official NCERT textbook file for **Class {class_level} {subject} - Chapter {chapter_num}: {chapter_name}** is not available on the server.

Please make sure the PDF is downloaded and placed inside `data/ncert_books` under `class{class_level}_{subject.lower()}`.
"""

    # Translate if necessary
    try:
        final_content = translate_markdown(chapter_content, lang)
    except Exception as e:
        print(f"Error during markdown translation: {e}")
        final_content = chapter_content

    lines = final_content.split("\n")
    return {"chunks": lines}

class ScoreRequest(BaseModel):
    name: str
    score: int
    subject: str
    class_level: str

@app.post("/submit_score")
def submit_score(data: ScoreRequest):
    file_path = "leaderboard.csv"
    file_exists = os.path.isfile(file_path)

    with open(file_path, "a", encoding="utf-8", newline="") as f:
        writer = csv.writer(f)
        if not file_exists:
            writer.writerow(["name", "score", "subject", "class_level", "timestamp"])
        writer.writerow([data.name, data.score, data.subject, data.class_level, datetime.now().strftime("%Y-%m-%d %H:%M")])
    return {"status": "Score saved"}

@app.get("/leaderboard")
def get_leaderboard(subject: str = None, class_level: str = None):
    file_path = "leaderboard.csv"
    if not os.path.exists(file_path):
        return {"leaderboard": []}

    best_scores = {}
    with open(file_path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            # Apply filters
            if subject and row.get("subject", "").lower() != subject.lower():
                continue
            if class_level and row.get("class_level", "") != class_level:
                # Handle old data without class_level
                if not (row.get("class_level") is None and class_level == "10"): # Default old to 10
                     continue

            name = row["name"]
            score = int(row["score"])
            # Keep only the highest score for each unique student name per subject/class
            key = f"{name}_{row.get('subject')}_{row.get('class_level')}"
            if key not in best_scores or score > int(best_scores[key]["score"]):
                best_scores[key] = row

    # Convert back to list and sort by score
    leaderboard = list(best_scores.values())
    leaderboard.sort(key=lambda x: int(x["score"]), reverse=True)

    return {"leaderboard": leaderboard[:10]}

from datetime import datetime as DateTime
import uvicorn

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
