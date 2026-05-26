import sys
sys.path.append('e:/MARK/MATA-Backend')
from dotenv import load_dotenv
load_dotenv('e:/MARK/MATA-Backend/.env')
from services.vlm_service import get_vlm_service
from services.llm_service import get_llm_service

with open('test.png', 'wb') as f:
    f.write(b'123')

vlm = get_vlm_service()
print("VLM Output:", vlm.analyze_diagram('test.png'))

llm = get_llm_service()
print("LLM Output:", llm.generate_explanation('test', 'test', 'teen'))
