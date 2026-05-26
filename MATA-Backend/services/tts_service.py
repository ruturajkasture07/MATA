from gtts import gTTS
import os
import uuid

class TTSService:
    def __init__(self, output_dir: str = "static/audio"):
        self.output_dir = output_dir
        if not os.path.exists(self.output_dir):
            os.makedirs(self.output_dir)

    def generate_audio(self, text: str) -> str:
        # Convert basic LaTeX to spoken words
        import re
        clean_text = text
        clean_text = re.sub(r'\\frac\{([^}]*)\}\{([^}]*)\}', r'\1 over \2', clean_text)
        clean_text = re.sub(r'\\sqrt\{([^}]*)\}', r'square root of \1', clean_text)
        clean_text = re.sub(r'\^2', r' squared', clean_text)
        clean_text = re.sub(r'\^3', r' cubed', clean_text)
        clean_text = re.sub(r'\\times', r' times ', clean_text)
        clean_text = re.sub(r'\\div', r' divided by ', clean_text)
        clean_text = re.sub(r'\\approx', r' approximately equals ', clean_text)
        
        # Strip remaining markdown and unhandled LaTeX symbols
        clean_text = re.sub(r'[*#_~`$]', '', clean_text)
        clean_text = re.sub(r'\\[a-zA-Z]+', '', clean_text) # strip unhandled backslash commands
        clean_text = re.sub(r'\[(.*?)\]\(.*?\)', r'\1', clean_text) # replace links with just text
        
        # Using Microsoft edge-tts for high-quality neural voice generation
        import subprocess
        filename = f"{uuid.uuid4()}.mp3"
        filepath = os.path.join(self.output_dir, filename)
        
        try:
            # Run edge-tts via subprocess
            # Voice can be changed: en-US-ChristopherNeural, en-US-JennyNeural, en-US-GuyNeural, etc.
            command = ["edge-tts", "--voice", "en-US-ChristopherNeural", "--text", clean_text, "--write-media", filepath]
            subprocess.run(command, check=True)
            
            # Return relative path for URL construction
            return f"/static/audio/{filename}"
        except Exception as e:
            print(f"TTS Error: {e}")
            return ""

tts_service = None

def get_tts_service():
    global tts_service
    if tts_service is None:
        tts_service = TTSService()
    return tts_service
