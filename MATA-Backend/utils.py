import os
import fitz # PyMuPDF

def parse_pdf(file_path: str) -> str:
    text = ""
    try:
        doc = fitz.open(file_path)
        for page in doc:
            text += page.get_text() + "\n"
        doc.close()
    except Exception as e:
        print(f"Error parsing PDF with PyMuPDF: {e}")
    return text

def cleanup_audio_files(directory: str = "static/audio", max_age_days: int = 1):
    import time
    now = time.time()
    try:
        for filename in os.listdir(directory):
            file_path = os.path.join(directory, filename)
            if os.path.isfile(file_path):
                if os.stat(file_path).st_mtime < now - max_age_days * 86400:
                    os.remove(file_path)
    except Exception as e:
        print(f"Error cleaning up audio files: {e}")
