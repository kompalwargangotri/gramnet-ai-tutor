import shutil
import os

src = "quiz_engine/quiz_database.csv"
dst = "../ai_tutor_app/assets/quiz_database.csv"

if os.path.exists(src):
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    shutil.copy(src, dst)
    print(f"Successfully bundled {src} to {dst}")
else:
    print(f"Source {src} not found!")
