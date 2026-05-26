import os
# pyrefly: ignore [missing-import]
from sqlalchemy import create_engine, Column, Integer, String, Text, DateTime, Boolean
# pyrefly: ignore [missing-import]
from sqlalchemy.orm import declarative_base, sessionmaker
from datetime import datetime
from dotenv import load_dotenv

load_dotenv()

# FR-157: PostgreSQL 14+ for user profiles and data persistence
# Fallback to SQLite if POSTGRES_URL is not set so it can still run locally without setup
DATABASE_URL = os.getenv("POSTGRES_URL") or "sqlite:///./mata_sessions.db"

# If using PostgreSQL, check_same_thread isn't needed
connect_args = {"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}

engine = create_engine(DATABASE_URL, connect_args=connect_args)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    name = Column(String)
    username = Column(String, unique=True, index=True)
    age = Column(Integer)
    is_blind = Column(Boolean, default=False)
    email = Column(String, unique=True, index=True)
    mobile_no = Column(String)
    password_hash = Column(String)
    profile_picture = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

class SessionLog(Base):
    __tablename__ = "sessions"

    id = Column(String, primary_key=True, index=True) # UUID
    user_id = Column(Integer, index=True)
    subject = Column(String, default="Session")
    timestamp = Column(DateTime, default=datetime.utcnow)
    age_level = Column(String)
    ocr_text = Column(Text)
    visual_text = Column(Text)
    explanation = Column(Text)

class QAHistory(Base):
    __tablename__ = "qa_history"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    session_id = Column(String, index=True)
    timestamp = Column(DateTime, default=datetime.utcnow)
    question = Column(Text)
    answer = Column(Text)

class FeedbackLog(Base):
    __tablename__ = "feedback"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    session_id = Column(String, index=True)
    user_id = Column(Integer, index=True)
    rating = Column(String) # 'Too Hard', 'Good', 'Too Easy'
    timestamp = Column(DateTime, default=datetime.utcnow)

# Create tables
try:
    Base.metadata.create_all(bind=engine)
    print(f"Database connected and tables created successfully. (URL: {DATABASE_URL.split('@')[-1] if '@' in DATABASE_URL else DATABASE_URL})")
except Exception as e:
    print(f"Database connection error: {e}")

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
