import os
import requests
import base64
from huggingface_hub import InferenceClient
from google import genai
from google.genai import types

class VLMService:
    def __init__(self):
        self.api_keys = [
            os.getenv("GEMINI_API_KEY_1"),
            os.getenv("GEMINI_API_KEY_2"),
            os.getenv("GEMINI_API_KEY") # Backwards compatibility
        ]
        self.api_keys = [k for k in self.api_keys if k]
        
        self.model_name = "gemini-3.5-flash"
        
        self.hf_api_token = os.getenv("HF_API_TOKEN")
        self.hf_model_id = "Salesforce/blip-image-captioning-base"
        self.hf_client = None
        if self.hf_api_token:
            self.hf_client = InferenceClient(token=self.hf_api_token)

    def analyze_diagram(self, image_path: str) -> str:
        error_msgs = []
        
        # Try Gemini API first with multiple keys
        if self.api_keys:
            with open(image_path, "rb") as f:
                image_bytes = f.read()

            for i, api_key in enumerate(self.api_keys):
                try:
                    print(f"[VLM] Attempting Gemini 3.5 Flash (Key {i+1}) on {image_path}...")
                    client = genai.Client(api_key=api_key)
                    
                    image_part = types.Part.from_bytes(
                        data=image_bytes,
                        mime_type="image/jpeg"
                    )
                    
                    response = client.models.generate_content(
                        model=self.model_name,
                        contents=[
                            "Describe this diagram or image in detail. Be educational and precise. If it's a technical diagram, explain the components. If it's just text, say 'No diagram present.'",
                            image_part
                        ]
                    )
                    
                    if response.text:
                        return response.text.strip()
                    else:
                        error_msgs.append(f"Gemini Key {i+1} Error: Empty response from model")
                except Exception as e:
                    error_msgs.append(f"Gemini Key {i+1} Exception: {str(e)}")
        else:
            error_msgs.append("GEMINI_API_KEYS missing.")
            
        # Fallback to Hugging Face InferenceClient
        if self.hf_client:
            try:
                print(f"[VLM] Falling back to HuggingFace ({self.hf_model_id})...")
                with open(image_path, "rb") as f:
                    image_bytes = f.read()
                
                # Use the client for better reliability
                result = self.hf_client.image_to_text(image_bytes, model=self.hf_model_id)
                if result:
                    if isinstance(result, list) and len(result) > 0 and "generated_text" in result[0]:
                        return f"[HF Fallback] {result[0]['generated_text']}"
                    return f"[HF Fallback] {str(result)}"
                return "HuggingFace returned no results."
            except Exception as e:
                error_msgs.append(f"HuggingFace Error: {str(e)}")
        else:
            error_msgs.append("HF_API_TOKEN missing or client not initialized.")
            
        return "Visual analysis failed with errors: " + " | ".join(error_msgs)

vlm_service = None

def get_vlm_service():
    global vlm_service
    if vlm_service is None:
        vlm_service = VLMService()
    return vlm_service
