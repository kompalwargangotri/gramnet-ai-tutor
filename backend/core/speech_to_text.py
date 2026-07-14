import sounddevice as sd
import numpy as np
import json
import os
from vosk import Model, KaldiRecognizer

print("Loading Offline Voice Models (English & Hindi)...")
try:
    # Ensure paths are correct relative to the execution directory
    en_path = "models/vosk-model-small-en-in-0.4"
    hi_path = "models/vosk-model-small-hi-0.22"

    if not os.path.exists(en_path) or not os.path.exists(hi_path):
        print("Warning: Vosk model folders not found in 'models/'. Voice input will be disabled.")
        model_en, model_hi = None, None
    else:
        model_en = Model(en_path)
        rec_en = KaldiRecognizer(model_en, 16000)

        model_hi = Model(hi_path)
        rec_hi = KaldiRecognizer(model_hi, 16000)
        print("Voice Models Loaded successfully!")
except Exception as e:
    print(f"Error loading voice models: {e}")
    model_en = None
    model_hi = None
    rec_en = None
    rec_hi = None

def listen(duration=5):
    if model_en is None or model_hi is None:
        print("Offline voice models are not available. Please check the models/ folder.")
        return ""

    print(f"\nListening for {duration} seconds... (Speak English or Hindi)")

    try:
        # Record audio at 16000 Hz, 1 channel
        audio_data = sd.rec(int(duration * 16000), samplerate=16000, channels=1, dtype='int16')
        sd.wait()  # Wait until recording is finished
        print("Processing audio...")

        # Convert numpy array to bytes for Vosk
        audio_bytes = audio_data.tobytes()

        # Process English
        rec_en.AcceptWaveform(audio_bytes)
        res_en = json.loads(rec_en.FinalResult())
        text_en = res_en.get("text", "")

        # Process Hindi
        rec_hi.AcceptWaveform(audio_bytes)
        res_hi = json.loads(rec_hi.FinalResult())
        text_hi = res_hi.get("text", "")

        # Guessing language based on output length (heuristic)
        if len(text_hi.strip()) > len(text_en.strip()):
            text = text_hi
            detected = "Hindi"
        else:
            text = text_en
            detected = "English"

        if not text.strip():
            print(" Could not understand audio")
            return ""

        print(f"Recognized ({detected}): {text}")
        return text.lower()

    except Exception as e:
        print(f"Error during audio recording: {e}")
        return ""
