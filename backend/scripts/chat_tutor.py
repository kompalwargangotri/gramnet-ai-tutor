import sys
import os

# Add backend root to search path
backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(backend_dir)

# Ensure current working directory is backend for index paths
os.chdir(backend_dir)

from core.tutor import tutor_response
from core.search_engine import load_index
from core.translator import to_english, to_original

def main():
    print("--------------------------------------------------")
    print("Loading NCERT Textbook Database & AI Models...")
    print("--------------------------------------------------")
    try:
        index, chunks = load_index()
        print("✅ Database loaded successfully.")
    except Exception as e:
        print(f"❌ Failed to load database: {e}")
        return

    print("\n🎓 AI Tutor is ready! Type your questions below.")
    print("   - You can type in English or Hindi.")
    print("   - Type 'exit' or 'quit' to close the session.\n")
    print("--------------------------------------------------")

    while True:
        try:
            query = input("Student Query: ").strip()
            if not query:
                continue
            if query.lower() in ("exit", "quit"):
                print("\nGoodbye! Happy learning!")
                break

            # Detect language (Devanagari for Hindi, else English)
            if any(ord(char) >= 0x0900 and ord(char) <= 0x097F for char in query):
                lang = "hi"
            else:
                lang = "en"

            print(f" (Translating query...)")
            query_en = to_english(query, lang)

            print(f" (Searching database and generating answer...)")
            answer_en = tutor_response(query_en, chunks, index)

            print(f" (Translating answer back...)")
            final_answer = to_original(answer_en, lang)

            print(f"\n🎓 Tutor ({lang.upper()}): {final_answer}")
            print("-" * 50)

        except KeyboardInterrupt:
            print("\nExiting...")
            break
        except Exception as e:
            print(f"An error occurred: {e}")
            print("-" * 50)

if __name__ == "__main__":
    main()
