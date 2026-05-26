import sys
sys.path.append('e:/MARK/MATA-Backend')
from dotenv import load_dotenv
load_dotenv()
from database import engine
# pyrefly: ignore [missing-import]
from sqlalchemy import text

try:
    with engine.begin() as conn:
        conn.execute(text("ALTER TABLE sessions ADD COLUMN subject VARCHAR;"))
    print("Column added successfully.")
except Exception as e:
    print("Error:", e)
