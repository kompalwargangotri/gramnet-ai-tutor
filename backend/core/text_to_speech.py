import asyncio
import edge_tts
import pyttsx3
import socket
import os

#  Internet check
def is_online():
    try:
        socket.create_connection(("8.8.8.8", 53), timeout=2)
        return True
    except:
        return False

#  Offline TTS
engine = pyttsx3.init()
engine.setProperty('rate', 170)

def speak_offline(text):
    try:
        engine.stop()
        engine.say(text)
        engine.runAndWait()
    except Exception as e:
        print("Offline TTS Error:", e)

#  Voice selection
def get_voice(lang):
    if lang == "hi":
        return "hi-IN-MadhurNeural"
    elif lang == "mr":
        return "mr-IN-AarohiNeural"
    else:
        return "en-IN-PrabhatNeural"

#  Online TTS
async def speak_online_async(text, lang):
    try:
        voice = get_voice(lang)
        file = "voice.mp3"

        communicate = edge_tts.Communicate(text, voice=voice)
        await communicate.save(file)

        os.system(f"start {file}")
    except Exception as e:
        print("Online TTS Error:", e)

def speak_online(text, lang):
    asyncio.run(speak_online_async(text, lang))

#  MAIN FUNCTION (THIS IS WHAT YOU ASKED)
def speak(text, lang="en"):
    if is_online():
        print(" Using ONLINE TTS (Edge)")
        speak_online(text, lang)
    else:
        print(" Using OFFLINE TTS")
        speak_offline(text)
