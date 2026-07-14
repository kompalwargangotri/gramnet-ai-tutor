import argostranslate.translate
from deep_translator import GoogleTranslator
import json
import os
from threading import Lock

CACHE_FILE = "data/translation_cache.json"
cache_lock = Lock()
TRANSLATION_CACHE = {}

def load_cache():
    global TRANSLATION_CACHE
    if os.path.exists(CACHE_FILE):
        try:
            with open(CACHE_FILE, "r", encoding="utf-8") as f:
                TRANSLATION_CACHE = json.load(f)
            print(f"[INFO] Loaded translation cache with {len(TRANSLATION_CACHE)} entries.")
        except Exception as e:
            print(f"[ERROR] Error loading translation cache: {e}")
            TRANSLATION_CACHE = {}

def save_cache():
    try:
        os.makedirs(os.path.dirname(CACHE_FILE), exist_ok=True)
        with open(CACHE_FILE, "w", encoding="utf-8") as f:
            json.dump(TRANSLATION_CACHE, f, ensure_ascii=False, indent=2)
    except Exception as e:
        print(f"[ERROR] Error saving translation cache: {e}")

load_cache()

#  Check internet
def is_online():
    import urllib.request
    import urllib.error
    try:
        # Check if we can actually reach connectivity check server within 2.0 seconds
        urllib.request.urlopen("https://clients3.google.com/generate_204", timeout=2.0)
        return True
    except urllib.error.HTTPError:
        # If we got an HTTPError, we connected to the server, so we are online
        return True
    except:
        return False

#  Offline translation (Argos)
def translate_offline(text, from_code, to_code):
    try:
        langs = argostranslate.translate.get_installed_languages()
        from_lang = next(l for l in langs if l.code == from_code)
        to_lang = next(l for l in langs if l.code == to_code)

        # Get the translation object
        translation = from_lang.get_translation(to_lang)

        # Bypass the stanza sentence splitter which tries to go online.
        # We split manually by common punctuation and translate chunks.
        import re
        sentences = re.split('([.!?।?])', text)
        result = ""

        # Merge punctuation back with sentences
        for i in range(0, len(sentences)-1, 2):
            sentence = sentences[i] + sentences[i+1]
            if sentence.strip():
                hyp = translation.hypotheses(sentence)
                val = hyp[0].value if hyp else sentence
                result += val + " "

        # Add last piece if any
        if len(sentences) % 2 != 0 and sentences[-1].strip():
            hyp = translation.hypotheses(sentences[-1])
            val = hyp[0].value if hyp else sentences[-1]
            result += val

        if result.strip():
            return result.strip()

        hyp = translation.hypotheses(text)
        return hyp[0].value if hyp else text

    except Exception as e:
        print(f" [ERROR] Offline translation failed: {e}")
        return text

#  Online translation (Google)
def translate_online(text, from_code, to_code):
    try:
        return GoogleTranslator(source=from_code, target=to_code).translate(text)
    except:
        return text

def to_english(text, lang):

    if lang == "en":
        return text.lower()

    translated = None

    # Try online first if we think we have internet
    if is_online():
        print(" Using ONLINE translation")
        translated = translate_online(text, lang, "en")

    # If online failed (returned same text or None) OR we are offline, use offline models
    if not translated or translated.strip() == text.strip():
        print(" Using OFFLINE translation fallback")
        if lang == "mr":
            print("\n[WARNING] Marathi offline translation is not supported by ArgosTranslate!")
            print("[WARNING] Please connect to the internet to use Marathi.\n")
        else:
            translated = translate_offline(text, lang, "en")

    # If even offline failed
    if not translated or translated.strip() == text.strip():
        print(" Translation completely failed")
        return text.lower()

    return translated.lower()


def to_original(text, lang, online=None):

    if lang == "en":
        return text

    stripped = text.strip()
    if not stripped:
        return text

    cache_key = f"{lang}:{stripped}"
    with cache_lock:
        if cache_key in TRANSLATION_CACHE:
            return TRANSLATION_CACHE[cache_key]

    translated = None
    is_on = online if online is not None else is_online()
    if is_on:
        translated = translate_online(stripped, "en", lang)

    if not translated or translated.strip() == stripped:
        # fallback offline (only Hindi supported properly)
        if lang == "mr":
            print("\n[WARNING] Marathi offline translation is not supported by ArgosTranslate!")
            return text
        else:
            translated = translate_offline(stripped, "en", lang)

    if not translated:
        translated = stripped

    with cache_lock:
        TRANSLATION_CACHE[cache_key] = translated
        save_cache()

    return translated
