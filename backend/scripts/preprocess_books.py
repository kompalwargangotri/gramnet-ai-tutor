import fitz  # PyMuPDF
import os
import re
import sys

# Add backend directory to path if needed
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

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

        # Drop caps fix: If current is a single uppercase letter, merge it with next_line
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
        # Common bullet markers in PDF text layers
        if line in ("n", "o", "•", "–"):
            # Find next non-empty line
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

def extract_to_markdown(pdf_path: str, subject: str, chapter_name: str) -> str:
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
            # Double-check page text is not empty or just a number
            if page_text and not page_text.isdigit():
                content_lines.append(f"**[Page {page_num}]**")
                content_lines.append(page_text)
                content_lines.append("")

    return "\n".join(content_lines)

def main():
    print("[INFO] Starting NCERT pre-processing pipeline...")
    output_dir = "data/ncert_processed"
    os.makedirs(output_dir, exist_ok=True)

    total_processed = 0
    total_missing = 0

    for subject, classes in NCERT_SYLLABUS.items():
        for class_level, chapters in classes.items():
            class_subject_dir = os.path.join(output_dir, f"class{class_level}_{subject.lower()}")
            os.makedirs(class_subject_dir, exist_ok=True)

            for i, ch_name in enumerate(chapters, 1):
                pdf_path = find_pdf_path(class_level, subject, i)
                filename = f"class{class_level}_{subject.lower()}_chapter{i:02d}.md"
                output_path = os.path.join(class_subject_dir, filename)

                if pdf_path and os.path.exists(pdf_path):
                    print(f"[PROCESS] Class {class_level} {subject} Ch {i}: {ch_name} -> {pdf_path}")
                    try:
                        markdown_content = extract_to_markdown(pdf_path, subject, ch_name)
                        with open(output_path, "w", encoding="utf-8") as f:
                            f.write(markdown_content)
                        total_processed += 1
                    except Exception as e:
                        print(f"[ERROR] Error processing {pdf_path}: {e}")
                else:
                    # Let's count it as missing
                    total_missing += 1

    print(f"\n[SUCCESS] Pre-processing complete!")
    print(f"   - Total chapters pre-processed: {total_processed}")
    print(f"   - Total chapters missing PDFs: {total_missing}")

if __name__ == "__main__":
    main()
