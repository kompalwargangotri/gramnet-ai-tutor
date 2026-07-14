import os
import shutil

def update_logo():
    # Source path (where the generated logo is stored in the artifacts)
    # Since I'm an AI, I'll assume the logo is already in the project assets or I'll copy it from a known location
    source_logo = "../assets/logo.png"
    target_dir = "../ai_tutor_app/assets"
    target_path = os.path.join(target_dir, "logo.png")

    if not os.path.exists(target_dir):
        os.makedirs(target_dir)

    print(f"Updating logo at {target_path}...")
    # In a real scenario, we'd copy the file here.
    # Assuming the user already has the logo.png in the root assets folder.
    if os.path.exists(source_logo):
        shutil.copy(source_logo, target_path)
        print("Logo updated successfully!")
    else:
        print(f"Source logo not found at {source_logo}. Please ensure the logo is generated.")

if __name__ == "__main__":
    update_logo()
