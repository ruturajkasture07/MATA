from fastapi import FastAPI, File, UploadFile, Form, Depends, Request, HTTPException, status
from fastapi.staticfiles import StaticFiles
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import Optional, List
# pyrefly: ignore [missing-import]
from sqlalchemy.orm import Session
import uuid
import os
import shutil
import json
# pyrefly: ignore [missing-import]
import redis
import hashlib
from dotenv import load_dotenv
from fastapi.middleware.cors import CORSMiddleware
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from datetime import timedelta

# Load environment variables from .env file
load_dotenv()

# pyrefly: ignore [missing-import]
import sentry_sdk
sentry_dsn = os.getenv("SENTRY_DSN")
if sentry_dsn:
    sentry_sdk.init(
        dsn=sentry_dsn,
        traces_sample_rate=1.0,
        profiles_sample_rate=1.0,
    )

# Import our AI services
from services.ocr_service import get_ocr_service
from services.vlm_service import get_vlm_service
from services.llm_service import get_llm_service
from services.tts_service import get_tts_service
from database import get_db, SessionLog, QAHistory, User, FeedbackLog
from auth import get_password_hash, verify_password, create_access_token, get_current_user, ACCESS_TOKEN_EXPIRE_MINUTES

limiter = Limiter(key_func=get_remote_address)
app = FastAPI(title="MATA Backend API", version="2.0")
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

allowed_origins_env = os.getenv("ALLOWED_ORIGINS")
origins = allowed_origins_env.split(",") if allowed_origins_env else [
    "http://localhost",
    "http://127.0.0.1",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

if not os.path.exists("static/audio"):
    os.makedirs("static/audio")
app.mount("/static", StaticFiles(directory="static"), name="static")

UPLOAD_DIR = "uploads"
if not os.path.exists(UPLOAD_DIR):
    os.makedirs(UPLOAD_DIR)

from utils import cleanup_audio_files
from fastapi import BackgroundTasks

def validate_file_size(max_mb: int):
    async def _validate(request: Request):
        if "content-length" not in request.headers:
            return None
        size = int(request.headers["content-length"])
        if size > max_mb * 1024 * 1024:
            raise HTTPException(status_code=413, detail=f"File too large. Maximum size is {max_mb}MB.")
        return size
    return _validate

class QARequest(BaseModel):
    session_id: str
    question: str
    history: Optional[List[dict]] = []

class RegisterRequest(BaseModel):
    name: str
    username: str
    age: int
    is_blind: bool
    email: str
    mobile_no: str
    password: str

class LoginRequest(BaseModel):
    username: str
    password: str

# FR-157: Redis for session caching
redis_url = os.getenv("REDIS_URL", "redis://localhost:6379/0")
try:
    redis_client = redis.from_url(redis_url, decode_responses=True)
    redis_client.ping()
    print("Redis connected successfully.")
except Exception as e:
    print(f"Redis connection failed, using in-memory dictionary fallback. Error: {e}")
    redis_client = {} # Fallback dictionary

@app.get("/")
def read_root():
    return {"message": "MATA Backend API is fully functional"}

@app.post("/api/v1/register")
@limiter.limit("10/minute")
def register_user(request: Request, req: RegisterRequest, db: Session = Depends(get_db)):
    # Check if username or email exists
    existing_user = db.query(User).filter((User.username == req.username) | (User.email == req.email)).first()
    if existing_user:
        return JSONResponse(status_code=400, content={"error": "Username or Email already exists"})
    
    password_hash = get_password_hash(req.password)
    
    new_user = User(
        name=req.name,
        username=req.username,
        age=req.age,
        is_blind=req.is_blind,
        email=req.email,
        mobile_no=req.mobile_no,
        password_hash=password_hash
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return {"message": "User registered successfully", "user_id": new_user.id}

@app.post("/api/v1/login")
@limiter.limit("20/minute")
def login_user(request: Request, req: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.username == req.username).first()
    
    password_valid = False
    if user:
        try:
            password_valid = verify_password(req.password, user.password_hash)
        except Exception:
            # Hash format is unrecognised (e.g. old SHA256 hash) — fall through to SHA256 check
            password_valid = False

    if not password_valid:
        # Fallback for old SHA256 passwords
        old_hash = hashlib.sha256(req.password.encode()).hexdigest()
        if not user or user.password_hash != old_hash:
            return JSONResponse(status_code=401, content={"error": "Invalid username or password"})
        else:
            # Upgrade the old SHA256 hash to bcrypt silently
            user.password_hash = get_password_hash(req.password)
            db.commit()

    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": str(user.id)}, expires_delta=access_token_expires
    )
    
    return {
        "message": "Login successful",
        "access_token": access_token,
        "token_type": "bearer",
        "user": {
            "id": user.id,
            "name": user.name,
            "username": user.username,
            "age": user.age,
            "is_blind": user.is_blind,
            "profile_picture": user.profile_picture
        }
    }

@app.post("/api/v1/process")
@limiter.limit("5/minute")
async def process_image(request: Request, background_tasks: BackgroundTasks, file: UploadFile = File(...), age_level: str = Form("teen"), current_user: str = Depends(get_current_user), db: Session = Depends(get_db), size: int = Depends(validate_file_size(5))):
    try:
        file_content = await file.read()
        
        session_id = str(uuid.uuid4())
        file_location = f"{UPLOAD_DIR}/{session_id}_{file.filename}"
        
        with open(file_location, "wb+") as file_object:
            file_object.write(file_content)

        ocr = get_ocr_service()
        ocr_text = ocr.process_image(file_location)

        vlm = get_vlm_service()
        visual_text = vlm.analyze_diagram(file_location)

        llm = get_llm_service()
        explanation = llm.generate_explanation(ocr_text, visual_text, age_level)

        tts = get_tts_service()
        audio_url_path = tts.generate_audio(explanation)
        full_audio_url = f"{str(request.base_url).rstrip('/')}{audio_url_path}" if audio_url_path else ""
        
        # Schedule audio cleanup
        background_tasks.add_task(cleanup_audio_files)

        # FR-77 Database logging
        new_session = SessionLog(
            id=session_id,
            user_id=int(current_user),
            subject=explanation[:25].strip() + "...",
            age_level=age_level,
            ocr_text=ocr_text,
            visual_text=visual_text,
            explanation=explanation
        )
        db.add(new_session)
        db.commit()

        # Cache to Redis for fast Q&A retrieval
        context_data = {
            "explanation": explanation,
            "ocr_text": ocr_text,
            "visual_text": visual_text
        }
        if isinstance(redis_client, dict):
            redis_client[session_id] = json.dumps(context_data)
        else:
            redis_client.setex(session_id, 86400, json.dumps(context_data)) # Cache for 24 hours

        if os.path.exists(file_location):
            os.remove(file_location)

        return {
            "session_id": session_id,
            "ocr_text": ocr_text,
            "layout": ["detected_paragraph", "detected_diagram"],
            "visuals": visual_text,
            "explanation": explanation,
            "audio_url": full_audio_url
        }

    except Exception as e:
        import traceback
        traceback.print_exc()
        return JSONResponse(status_code=500, content={"error": str(e)})

@app.post("/api/v1/qa")
@limiter.limit("20/minute")
async def ask_question(request: Request, req: QARequest, db: Session = Depends(get_db)):
    # Retrieve context from Redis cache (fallback to DB if not found)
    context_str = "No context available."
    print(f"[QA Endpoint] Looking up context for session: {req.session_id}")
    
    try:
        if isinstance(redis_client, dict):
            cached_data = redis_client.get(req.session_id)
        else:
            cached_data = redis_client.get(req.session_id)
            
        if cached_data:
            print("[QA Endpoint] Found context in Redis cache!")
            data = json.loads(cached_data)
            context_str = f"Page Text: {data.get('ocr_text', '')}\nVisual Diagram Details: {data.get('visual_text', '')}\nSummary: {data.get('explanation', '')}"
        else:
            print("[QA Endpoint] Not found in Redis. Checking Database fallback...")
            # Fallback to DB
            session_log = db.query(SessionLog).filter(SessionLog.id == req.session_id).first()
            if session_log:
                print("[QA Endpoint] Found context in Database!")
                context_str = f"Page Text: {session_log.ocr_text}\nVisual Diagram Details: {session_log.visual_text}\nSummary: {session_log.explanation}"
            else:
                print("[QA Endpoint] WARNING: session_id not found anywhere. Context remains empty.")
    except Exception as e:
        print(f"[QA Endpoint] Error retrieving context: {e}")

    llm = get_llm_service()
    answer = llm.answer_question(req.question, context_str)

    tts = get_tts_service()
    audio_url_path = tts.generate_audio(answer)
    full_audio_url = f"{str(request.base_url).rstrip('/')}{audio_url_path}" if audio_url_path else ""

    # Log QA History
    qa_record = QAHistory(session_id=req.session_id, question=req.question, answer=answer)
    db.add(qa_record)
    db.commit()

    return {
        "answer": answer,
        "audio_url": full_audio_url
    }

@app.get("/api/v1/sessions")
def get_sessions(current_user: str = Depends(get_current_user), db: Session = Depends(get_db)):
    # Return sessions with full explanations and their chat history
    sessions = db.query(SessionLog).filter(SessionLog.user_id == int(current_user)).order_by(SessionLog.timestamp.desc()).limit(20).all()
    
    result = []
    for s in sessions:
        # Fetch associated QA history for this session
        qas = db.query(QAHistory).filter(QAHistory.session_id == s.id).order_by(QAHistory.timestamp.asc()).all()
        chat_history = []
        for qa in qas:
            chat_history.append({"user": qa.question, "bot": qa.answer})
            
        result.append({
            "id": s.id, 
            "subject": s.subject,
            "timestamp": s.timestamp.isoformat(), 
            "age_level": s.age_level, 
            "explanation": s.explanation,
            "explanation_preview": s.explanation[:50] + "..." if s.explanation else "",
            "chat_history": chat_history
        })
        
    return {"sessions": result}

@app.delete("/api/v1/sessions/{session_id}")
def delete_session(session_id: str, current_user: str = Depends(get_current_user), db: Session = Depends(get_db)):
    session = db.query(SessionLog).filter(SessionLog.id == session_id, SessionLog.user_id == int(current_user)).first()
    if session:
        db.delete(session)
        db.query(QAHistory).filter(QAHistory.session_id == session_id).delete()
        db.commit()
    else:
        return JSONResponse(status_code=404, content={"error": "Session not found or unauthorized"})
    return {"status": "deleted"}

@app.delete("/api/v1/sessions")
def clear_all_history(current_user: str = Depends(get_current_user), db: Session = Depends(get_db)):
    # Delete QAHistory for all sessions belonging to the user
    user_sessions = db.query(SessionLog.id).filter(SessionLog.user_id == int(current_user)).subquery()
    db.query(QAHistory).filter(QAHistory.session_id.in_(user_sessions)).delete(synchronize_session=False)
    # Delete the sessions themselves
    db.query(SessionLog).filter(SessionLog.user_id == int(current_user)).delete(synchronize_session=False)
    db.commit()
    return {"status": "cleared"}

@app.put("/api/v1/profile")
def update_profile(request: Request, name: str = Form(...), age: int = Form(...), is_blind: bool = Form(...), current_user: str = Depends(get_current_user), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == int(current_user)).first()
    if user:
        user.name = name
        user.age = age
        user.is_blind = is_blind
        db.commit()
    return {"message": "Profile updated"}

@app.get("/api/v1/profile")
def get_profile(current_user: str = Depends(get_current_user), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == int(current_user)).first()
    if not user:
        return JSONResponse(status_code=404, content={"error": "User not found"})
    return {
        "id": user.id,
        "name": user.name,
        "username": user.username,
        "age": user.age,
        "is_blind": user.is_blind,
        "email": user.email,
        "mobile_no": user.mobile_no,
        "profile_picture": user.profile_picture
    }

@app.post("/api/v1/feedback")
@limiter.limit("20/minute")
def submit_feedback(request: Request, session_id: str = Form(...), rating: str = Form(...), current_user: str = Depends(get_current_user), db: Session = Depends(get_db)):
    # Validate session belongs to user
    session = db.query(SessionLog).filter(SessionLog.id == session_id, SessionLog.user_id == int(current_user)).first()
    if not session:
        return JSONResponse(status_code=404, content={"error": "Session not found or unauthorized"})
        
    feedback = FeedbackLog(
        session_id=session_id,
        user_id=int(current_user),
        rating=rating
    )
    db.add(feedback)
    db.commit()
    return {"message": "Feedback submitted successfully"}

@app.post("/api/v1/profile/picture")
async def upload_profile_picture(request: Request, file: UploadFile = File(...), current_user: str = Depends(get_current_user), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == int(current_user)).first()
    if not user:
        return JSONResponse(status_code=404, content={"error": "User not found"})
        
    file_content = await file.read()
    if len(file_content) > 5 * 1024 * 1024:
        return JSONResponse(status_code=400, content={"error": "File size exceeds 5MB limit"})
        
    file_ext = file.filename.split(".")[-1]
    file_name = f"profile_{user.id}_{uuid.uuid4().hex[:8]}.{file_ext}"
    file_location = f"{UPLOAD_DIR}/{file_name}"
    
    with open(file_location, "wb+") as f:
        f.write(file_content)
        
    pic_url = f"{str(request.base_url).rstrip('/')}/uploads/{file_name}"
    user.profile_picture = pic_url
    db.commit()
    
    return {"profile_picture": pic_url}

from utils import parse_pdf
@app.post("/api/v1/process_pdf")
@limiter.limit("5/minute")
async def process_pdf(request: Request, background_tasks: BackgroundTasks, file: UploadFile = File(...), age_level: str = Form("teen"), current_user: str = Depends(get_current_user), db: Session = Depends(get_db), size: int = Depends(validate_file_size(15))):
    file_content = await file.read()
    
    session_id = str(uuid.uuid4())
    file_location = f"{UPLOAD_DIR}/{session_id}_{file.filename}"
    
    with open(file_location, "wb+") as f:
        f.write(file_content)
        
    ocr_text = parse_pdf(file_location)
    visual_text = "No visual diagrams extracted from PDF."
    
    llm = get_llm_service()
    explanation = llm.generate_explanation(ocr_text, visual_text, age_level)

    tts = get_tts_service()
    audio_url_path = tts.generate_audio(explanation)
    full_audio_url = f"{str(request.base_url).rstrip('/')}{audio_url_path}" if audio_url_path else ""
    
    background_tasks.add_task(cleanup_audio_files)

    new_session = SessionLog(
        id=session_id,
        user_id=int(current_user),
        subject=explanation[:25].strip() + "...",
        age_level=age_level,
        ocr_text=ocr_text,
        visual_text=visual_text,
        explanation=explanation
    )
    db.add(new_session)
    db.commit()

    context_data = {
        "explanation": explanation,
        "ocr_text": ocr_text,
        "visual_text": visual_text
    }
    if isinstance(redis_client, dict):
        redis_client[session_id] = json.dumps(context_data)
    else:
        redis_client.setex(session_id, 86400, json.dumps(context_data))

    if os.path.exists(file_location):
        os.remove(file_location)

    return {
        "session_id": session_id,
        "ocr_text": ocr_text,
        "layout": ["detected_paragraph"],
        "visuals": visual_text,
        "explanation": explanation,
        "audio_url": full_audio_url
    }

@app.post("/api/v1/process_images_batch")
@limiter.limit("5/minute")
async def process_images_batch(request: Request, background_tasks: BackgroundTasks, files: List[UploadFile] = File(...), age_level: str = Form("teen"), current_user: str = Depends(get_current_user), db: Session = Depends(get_db)):
    try:
        session_id = str(uuid.uuid4())
        combined_ocr_text = ""
        combined_visual_text = ""
        
        ocr = get_ocr_service()
        vlm = get_vlm_service()
        
        for i, file in enumerate(files):
            file_content = await file.read()
            if len(file_content) > 5 * 1024 * 1024:
                continue # Skip files that are too large in a batch
            file_location = f"{UPLOAD_DIR}/{session_id}_{i}_{file.filename}"
            with open(file_location, "wb+") as f:
                f.write(file_content)
                
            combined_ocr_text += f"--- Page {i+1} ---\n" + ocr.process_image(file_location) + "\n\n"
            combined_visual_text += f"--- Page {i+1} ---\n" + vlm.analyze_diagram(file_location) + "\n\n"
            
            os.remove(file_location)
            
        llm = get_llm_service()
        explanation = llm.generate_explanation(combined_ocr_text, combined_visual_text, age_level)

        tts = get_tts_service()
        audio_url_path = tts.generate_audio(explanation)
        full_audio_url = f"{str(request.base_url).rstrip('/')}{audio_url_path}" if audio_url_path else ""
        
        background_tasks.add_task(cleanup_audio_files)

        new_session = SessionLog(
            id=session_id,
            user_id=int(current_user),
            subject=explanation[:25].strip() + "...",
            age_level=age_level,
            ocr_text=combined_ocr_text,
            visual_text=combined_visual_text,
            explanation=explanation
        )
        db.add(new_session)
        db.commit()

        context_data = {
            "explanation": explanation,
            "ocr_text": combined_ocr_text,
            "visual_text": combined_visual_text
        }
        if isinstance(redis_client, dict):
            redis_client[session_id] = json.dumps(context_data)
        else:
            redis_client.setex(session_id, 86400, json.dumps(context_data))

        return {
            "session_id": session_id,
            "ocr_text": combined_ocr_text,
            "layout": ["detected_paragraph"],
            "visuals": combined_visual_text,
            "explanation": explanation,
            "audio_url": full_audio_url
        }

    except Exception as e:
        return JSONResponse(status_code=500, content={"error": str(e)})

from fastapi.responses import FileResponse
@app.get("/api/v1/audio/{session_id}")
def stream_audio(session_id: str, current_user: str = Depends(get_current_user)):
    file_path = f"static/audio/{session_id}.mp3"
    if os.path.exists(file_path):
        return FileResponse(file_path, media_type="audio/mpeg")
    return JSONResponse(status_code=404, content={"error": "Audio not found"})

if __name__ == "__main__":
    import uvicorn
    use_https = os.getenv("USE_HTTPS", "false").lower() == "true"
    if use_https:
        print("Starting server with HTTPS...")
        cert_path = "cert.pem"
        key_path = "key.pem"
        if not os.path.exists(cert_path) or not os.path.exists(key_path):
            print("Generating self-signed SSL certificates for local dev...")
            os.system(f'openssl req -x509 -newkey rsa:4096 -nodes -out {cert_path} -keyout {key_path} -days 365 -subj "/CN=localhost"')
        uvicorn.run("main:app", host="0.0.0.0", port=8000, ssl_keyfile=key_path, ssl_certfile=cert_path)
    else:
        print("Starting server with plain HTTP...")
        uvicorn.run("main:app", host="0.0.0.0", port=8000)
