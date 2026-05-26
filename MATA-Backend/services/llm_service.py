import os
import requests
from huggingface_hub import InferenceClient
from google import genai

class LLMService:
    def __init__(self):
        self.api_keys = [
            os.getenv("GEMINI_API_KEY_1"),
            os.getenv("GEMINI_API_KEY_2"),
            os.getenv("GEMINI_API_KEY") # Backwards compatibility
        ]
        self.api_keys = [k for k in self.api_keys if k]
        
        self.model_name = "gemini-3.5-flash"
        
        # Hugging Face fallback setup
        self.hf_api_token = os.getenv("HF_API_TOKEN")
        self.hf_model_id = "meta-llama/Llama-3.3-70B-Instruct"

    def _query_api(self, prompt: str) -> str:
        error_msgs = []
        
        # Try Gemini API first with multiple keys, rotating starting from the last working key
        if self.api_keys:
            num_keys = len(self.api_keys)
            for i in range(num_keys):
                # Try the key at the current index, then increment
                api_key = self.api_keys[0]
                try:
                    client = genai.Client(api_key=api_key)
                    response = client.models.generate_content(
                        model=self.model_name,
                        contents=prompt
                    )
                    if response.text:
                        return response.text.strip()
                    else:
                        error_msgs.append(f"Gemini Key {i+1} Error: Empty response from model")
                        self.api_keys.append(self.api_keys.pop(0))
                except Exception as e:
                    error_msgs.append(f"Gemini Key {i+1} Request Error: {str(e)}")
                    self.api_keys.append(self.api_keys.pop(0))
        else:
            error_msgs.append("GEMINI_API_KEYS not found.")
            
        # Fallback to Hugging Face API
        if self.hf_api_token:
            try:
                client = InferenceClient(token=self.hf_api_token)
                res = client.chat_completion(
                    model=self.hf_model_id,
                    messages=[{"role": "user", "content": prompt}],
                    max_tokens=500
                )
                return res.choices[0].message.content.strip()
            except Exception as e:
                error_msgs.append(f"HuggingFace Request Error: {str(e)}")
        else:
            error_msgs.append("HF_API_TOKEN not found.")
            
        return "LLM Request failed with errors: " + " | ".join(error_msgs)

    def generate_explanation(self, ocr_text: str, visual_text: str, age_level: str) -> str:
        level_instructions = {
            "child": "Use simple vocabulary suitable for a 10-year-old child. Use analogies and simple examples.",
            "teen": "Use standard educational vocabulary for a high school student. Include technical terms.",
            "adult": "Use full technical content and formal language for a college student."
        }
        instruction = level_instructions.get(age_level.lower(), level_instructions["teen"])
        
        prompt = (
            f"You are MATA, an expert AI tutor. Explain the following textbook content. {instruction}\n"
            f"Please use Markdown for formatting (headers, bold, bullet points) and use LaTeX enclosed in single $ for math equations.\n"
            f"Only output the explanation, no extra conversational text.\n\n"
            f"Text extracted from page: {ocr_text}\n"
            f"Visual descriptions from page: {visual_text}\n"
            f"Explain this content in plain spoken text."
        )

        return self._query_api(prompt)

    def answer_question(self, question: str, context: str) -> str:
        prompt = (
            f"You are MATA, an AI tutor. Answer strictly based on the following textbook context:\n{context}\n\n"
            f"Please use Markdown for formatting and use LaTeX enclosed in single $ for math equations.\n"
            f"If unrelated, say 'That question doesn't seem to be about this page. Want me to answer anyway?'\n\n"
            f"Question: {question}"
        )

        return self._query_api(prompt)

llm_service = None

def get_llm_service():
    global llm_service
    if llm_service is None:
        llm_service = LLMService()
    return llm_service
