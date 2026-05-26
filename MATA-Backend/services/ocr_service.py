import pytesseract
import cv2
import numpy as np
from PIL import Image
import os
import requests

class OCRService:
    def __init__(self):
        self.hf_api_token = os.getenv("HF_API_TOKEN")
        self.trocr_api_url = "https://api-inference.huggingface.co/models/microsoft/trocr-base-printed"

    def preprocess_image(self, image_path: str) -> str:
        # FR-35: Preprocessing - noise reduction, deskew, etc.
        img = cv2.imread(image_path, cv2.IMREAD_COLOR)
        if img is None:
            return image_path
            
        # 1. Grayscale
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        
        # 2. Noise Reduction
        blur = cv2.GaussianBlur(gray, (5, 5), 0)
        
        # 3. Binarization (Thresholding)
        _, thresh = cv2.threshold(blur, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
        
        # Save preprocessed with a clear suffix to avoid overwriting original
        base, ext = os.path.splitext(image_path)
        prep_path = f"{base}_prep{ext}"
        cv2.imwrite(prep_path, thresh)
        return prep_path

    def extract_text_trocr_api(self, image_path: str) -> str:
        if not self.hf_api_token:
            raise Exception("HF_API_TOKEN not set")
            
        headers = {"Authorization": f"Bearer {self.hf_api_token}"}
        with open(image_path, "rb") as f:
            data = f.read()
            
        response = requests.post(self.trocr_api_url, headers=headers, data=data, timeout=30)
        if response.status_code == 200:
            result = response.json()
            if isinstance(result, list) and len(result) > 0:
                return result[0].get("generated_text", "")
            return str(result)
        else:
            raise Exception(f"API Error {response.status_code}: {response.text}")

    def extract_text_fallback(self, image_path: str) -> str:
        # FR-39: Fallback to Tesseract
        image = Image.open(image_path)
        return pytesseract.image_to_string(image)

    def process_image(self, image_path: str) -> str:
        # 1. Preprocess
        prep_path = self.preprocess_image(image_path)
        
        text = ""
        # 2. Attempt TrOCR via API if token exists
        if self.hf_api_token:
            try:
                print(f"Attempting TrOCR via API on {prep_path}...")
                text = self.extract_text_trocr_api(prep_path)
            except Exception as e:
                print(f"TrOCR API failed: {e}. Falling back to Tesseract.")
                text = self.extract_text_fallback(prep_path)
        else:
            print("No HF_API_TOKEN found. Using Tesseract OCR locally.")
            text = self.extract_text_fallback(prep_path)
            
        # Clean up preprocessed file ONLY if it was created as a separate file
        if prep_path != image_path and os.path.exists(prep_path):
            os.remove(prep_path)
            
        return text

ocr_service = None

def get_ocr_service():
    global ocr_service
    if ocr_service is None:
        ocr_service = OCRService()
    return ocr_service
