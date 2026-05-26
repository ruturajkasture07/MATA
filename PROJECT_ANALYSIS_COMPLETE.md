# ============================================================
#  MATA / MARK — COMPLETE PROJECT ANALYSIS DOCUMENT
#  Multimodal Accessible Textbook Assistant
#  Generated: May 2026
# ============================================================

## TABLE OF CONTENTS
1.  Project Overview & Mission
2.  Repository Structure (every file explained)
3.  Technology Stack (Frontend + Backend)
4.  Flutter App — Architecture & Every Screen
5.  Backend — FastAPI Architecture & Every Endpoint
6.  AI Pipeline — End-to-End Data Flow
7.  Database Schema
8.  Accessibility System (The Core Design Philosophy)
9.  Services — Detailed Breakdown
10. Configuration & Environment
11. Features Implemented (Complete List)
12. What Is NOT Yet Implemented (Gaps)
13. Suggestions — New Features to Add
14. Suggestions — Advancements for Visually Impaired Users
15. Known Issues & Technical Debt

---

## 1. PROJECT OVERVIEW & MISSION

**Full Name:** MATA — Multimodal Accessible Textbook Assistant
**Bot/AI Persona Name:** MARK — Multimodal Accessible Reading Knowledge-bot
**Platform:** Flutter (Cross-platform mobile app targeting Android & iOS)
**Backend:** Python FastAPI REST API
**College:** MIT Academy of Engineering, Alandi (D), Pune – 412105 (Affiliated to SPPU)
**Academic Year:** 2025–26
**Version:** 2.0 (App Edition — converted from earlier web version 1.0)

### Team
| Name | Exam Seat No. | Role |
|------|--------------|------|
| Ruturaj Kasture | 202301040275 | Team Lead / AI Pipeline |
| Maitreyee Majumdar | 202301040277 | Backend / LLM Integration |
| Kanishka Amrutkar | 202301040244 | Mobile App / UI |
| Amisha Singh | 202301100041 | OCR / Vision Module |

**Guide:** Mrs. Neha Hajare | **Coordinator:** Dr. Kanchan Dhote | **HoD:** Dr. Pramod Ganjewar

### What MATA Does
MATA is an AI-powered educational accessibility tool that:
1. Lets users point their phone camera at any textbook page (or upload an image)
2. Automatically performs OCR (Optical Character Recognition) to extract all text
3. Uses a Vision-Language Model (VLM) to understand diagrams, charts, and images
4. Passes extracted content to a Large Language Model (LLM) that generates a clear, age-adapted explanation
5. Converts that explanation to spoken audio (Text-to-Speech / TTS)
6. Allows follow-up voice questions — the AI bot "MARK" answers in context

**Primary Users:**
- Visually impaired students who cannot read textbooks independently
- Young learners (ages 8–16) who benefit from simplified audio explanations
- Anyone who prefers audio-based or hands-free learning

---

## 2. REPOSITORY STRUCTURE (Every File)

```
E:\MARK\
│
├── MATA-App/                    ← The Flutter Mobile Application
│   ├── lib/
│   │   ├── main.dart            ← App entry point, routing, theme
│   │   ├── screens/
│   │   │   ├── login_screen.dart        ← Auth: Profile selector + login form
│   │   │   ├── register_screen.dart     ← New user registration form
│   │   │   ├── home_screen.dart         ← Home dashboard (scan/upload CTA)
│   │   │   ├── camera_screen.dart       ← Live camera viewfinder + capture
│   │   │   ├── configuration_screen.dart ← Age/difficulty level selector
│   │   │   ├── result_screen.dart       ← Learning space + MARK Q&A chat
│   │   │   ├── history_screen.dart      ← Past session list (UI only, mock data)
│   │   │   ├── profile_screen.dart      ← User profile display + logout
│   │   │   └── settings_screen.dart     ← App settings (partial implementation)
│   │   ├── services/
│   │   │   ├── api_service.dart         ← HTTP client to call backend REST API
│   │   │   ├── narrator_service.dart    ← Singleton TTS narrator (screen reader)
│   │   │   └── voice_service.dart       ← Singleton STT (speech-to-text) service
│   │   └── widgets/
│   │       └── accessible_widget.dart   ← Custom wrapper: tap=read, double-tap=activate
│   ├── pubspec.yaml             ← Flutter dependencies
│   ├── assets/images/           ← Image assets folder (declared but may be empty)
│   └── android/ ios/ web/ ...  ← Platform-specific build files
│
├── MATA-Backend/                ← Python FastAPI REST Backend
│   ├── main.py                  ← API server with all route handlers
│   ├── database.py              ← SQLAlchemy ORM models + DB setup
│   ├── services/
│   │   ├── ocr_service.py       ← OCR pipeline (TrOCR API + Tesseract fallback)
│   │   ├── vlm_service.py       ← Visual analysis (Gemini 2.5 Flash + BLIP fallback)
│   │   ├── llm_service.py       ← Explanation + Q&A (Gemini 2.5 Flash + Llama 3.3 70B)
│   │   └── tts_service.py       ← Audio generation (gTTS)
│   ├── requirements.txt         ← Python package dependencies
│   ├── .env                     ← API keys (HF, Gemini, Postgres, Redis)
│   ├── mata_sessions.db         ← SQLite database (local dev fallback)
│   ├── static/audio/            ← Generated MP3 audio files served statically
│   └── uploads/                 ← Temporary image upload directory
│
├── mark/                        ← Default Flutter project (boilerplate, unused)
│   └── lib/main.dart            ← Flutter counter demo app (not MATA)
│
├── SRS_MARK_App_IEEE_v2.pdf     ← IEEE Std 830-1998 Software Requirements Spec
├── UI_UX Design Specification_MATA.pdf  ← Original UI/UX design document
├── srs_text.txt                 ← Plain-text extraction of the SRS PDF
├── uiux_text.txt                ← Plain-text extraction of the UI/UX PDF
├── read_pdf.py                  ← Utility script to extract PDF text
└── .venv/                       ← Python virtual environment (root level)
```

---

## 3. TECHNOLOGY STACK

### Frontend (Mobile App)
| Technology | Version | Purpose |
|-----------|---------|---------|
| Flutter | ^3.0 SDK | Cross-platform UI framework (Dart language) |
| Dart | ≥3.0 | Programming language |
| google_fonts ^8.0.2 | | Typography — "Outfit" font family |
| flutter_animate ^4.5.2 | | Micro-animations (fadeIn, slideY, scaleXY, etc.) |
| flutter_tts ^4.2.5 | | Text-to-Speech for audio playback & screen reader |
| speech_to_text ^7.3.0 | | Speech-to-Text for voice Q&A input |
| camera ^0.12.0+1 | | Live camera feed & photo capture |
| image_picker ^1.0.4 | | Gallery image selection (dependency added, not all screens use it) |
| file_picker ^11.0.2 | | File picker for document upload |
| http ^1.1.0 | | HTTP client for REST API calls |
| shared_preferences ^2.2.1 | | Local storage for session persistence (login state) |
| flutter_secure_storage ^10.0.0 | | Secure storage (added as dep, not heavily used yet) |
| cupertino_icons ^1.0.2 | | iOS-style icon set |

### Backend (Server)
| Technology | Version | Purpose |
|-----------|---------|---------|
| Python | — | Server language |
| FastAPI 0.103.1 | | REST API framework (async, auto-docs) |
| Uvicorn 0.23.2 | | ASGI server to run FastAPI |
| SQLAlchemy | Latest | ORM for database models |
| SQLite | Built-in | Local development database |
| PostgreSQL 14+ | Optional | Production database (configured via POSTGRES_URL env) |
| Redis | Optional | Session context caching (24h TTL) |
| python-multipart 0.0.6 | | File upload handling |
| Pydantic 2.3.0 | | Request/response data validation |
| python-dotenv | | Environment variable loading |
| psycopg2-binary | | PostgreSQL driver |

### AI/ML Services
| Service | Provider | Purpose |
|---------|---------|---------|
| TrOCR (trocr-base-printed) | Microsoft / HuggingFace API | Primary OCR — Transformer-based text extraction |
| Tesseract OCR | Open source (local) | Fallback OCR when HF token unavailable |
| pytesseract | Python wrapper | Python interface to Tesseract |
| OpenCV (cv2) | — | Image preprocessing (grayscale, blur, binarization) |
| Pillow (PIL) | — | Image file loading |
| Gemini 2.5 Flash | Google AI Studio | Primary VLM + LLM (visual analysis + explanation + Q&A) |
| BLIP (blip-image-captioning-base) | Salesforce / HuggingFace | Fallback VLM for image captioning |
| Llama 3.3 70B Instruct | Meta / HuggingFace | Fallback LLM for text generation |
| gTTS (Google Text-to-Speech) | Google | Audio generation (MP3) |
| huggingface_hub | HuggingFace | Unified inference client for HF models |
| redis | Redis | In-memory session context cache |

---

## 4. FLUTTER APP — ARCHITECTURE & EVERY SCREEN

### App Entry Point: main.dart
- `main()` runs asynchronously — checks `SharedPreferences` for saved `user_id`
- If `user_id` exists → goes directly to `MainNavigator` (bottom nav shell)
- If not → goes to `LoginScreen` first
- **Theme:** Dark mode with Slate-900 background (`#0F172A`), Blue-500 primary (`#3B82F6`), Emerald-500 secondary (`#10B981`), Outfit font via Google Fonts
- `MainNavigator` is a `StatefulWidget` wrapping 4 tab screens in a `BottomNavigationBar`

### Screen 1: LoginScreen (login_screen.dart)
**What it does:** Two-mode authentication screen
**Mode A — Profile Selection:**
- Shows "Select Profile" title
- Card for "Guest" profile → immediately enters app without any account
- Card for "Login / Register" → switches to Mode B
- NarratorService speaks welcome message on load

**Mode B — Login Form:**
- Username + Password text fields (large fonts: 24px, for accessibility)
- Glassmorphism card wrapping both fields
- Blue gradient "LOGIN" button (full width, 70px height)
- "New user? Register here" link → navigates to RegisterScreen
- On success: saves `user_id`, `username`, `name` to SharedPreferences → navigates to MainNavigator
- On failure: shows SnackBar + NarratorService speaks error

**Accessibility:** On tap = reads label, on double-tap = activates (via AccessibleWidget)

---

### Screen 2: RegisterScreen (register_screen.dart)
**What it does:** New user account creation
**Fields:**
- Full Name (text)
- Username (text)
- Age (numeric keyboard)
- Email (email keyboard)
- Mobile No. (phone keyboard)
- Password (obscured text)
- Visually Impaired toggle (Dropdown: "Yes" / "No") — this `is_blind` flag is stored in DB

**Behavior:**
- Calls `ApiService.register()` → POST /api/v1/register
- On success → SnackBar + pops back to login
- On failure → SnackBar with error message
- Loading state shows `CircularProgressIndicator`

---

### Screen 3: HomeScreen (home_screen.dart)
**What it does:** Main dashboard — the first screen logged-in users see
**UI Elements:**
- Transparent AppBar ("Home Dashboard") over radial gradient background
- Giant glassmorphic card (85% width, 45% height) — the main "Scan or Upload Page" button
  - Blue-to-Emerald gradient
  - Scanner icon with breathing pulse animation (scaleXY 1.0→1.05, 1.5s loop)
  - Text: "Scan or Upload Page" (34px, bold)
- FAB in bottom-right: microphone icon (purple-to-pink gradient) — the "Ask MARK" button
  - When `_isMarkListening = true`: mic icon scales up (1.3x), glow effect intensifies

**Voice Trigger (MARK on Home):**
- Double-tap MARK FAB → `_triggerMark()` runs
- NarratorService says: "Hi, what do you want to learn today? You can say 'Scan a page' or ask me a general question."
- After 4-second delay → STT starts listening for 5 seconds
- If user says "scan" or "camera" → opens CameraScreen
- Otherwise → reads back what was heard

**Animations:**
- Main card: `fadeIn(800ms) + slideY(begin: 0.1)`
- MARK FAB: continuous `slideY(-0.05 to 0.05, 2s loop)` (floating effect)
- NarratorService speaks "Home screen. The main button..." on init

---

### Screen 4: CameraScreen (camera_screen.dart)
**What it does:** Live camera viewfinder for capturing textbook pages
**Initialization:**
- `availableCameras()` → selects first back camera
- `ResolutionPreset.high` — captures at high resolution
- After 2 seconds: `HapticFeedback.vibrate()` + narrator says "Edges detected. Hold still." (simulated edge detection)

**UI Layout:**
- Top 70% of screen: full-screen camera preview (`CameraPreview`) with rounded bottom corners
- Bottom 30%: glassmorphic "Double Tap to Capture" area
  - Blue gradient background
  - Camera icon with pulse animation (scaleXY 1.0→1.1, 1s loop)
  - "Double Tap to Capture" text (26px)
- Top-left: translucent back button (blurred glass effect)

**Capture Flow:**
- Double-tap bottom area → `_captureImage()`
- `_controller.takePicture()` → saves to temp file
- `HapticFeedback.heavyImpact()` twice (success vibration pattern)
- NarratorService: "Page captured."
- Navigates to `ConfigurationScreen(imagePath: ...)`

---

### Screen 5: ConfigurationScreen (configuration_screen.dart)
**What it does:** User selects reading difficulty level before processing
**Three Difficulty Levels:**
| Level | Color | Icon | Description |
|-------|-------|------|-------------|
| Child | Emerald Green #34D399 | child_care | Simple vocabulary, analogies, 10-year-old level |
| Teen | Yellow #FBBF24 | school | High school vocabulary, technical terms |
| Adult | Blue #60A5FA | person | Full technical content, college level |

**UI:**
- Each level is a full-width animated card (glassmorphism)
- Selected level: highlighted border + background glow + checkmark icon appears
- NarratorService speaks selected level name
- "PROCESS IMAGE" button (blue gradient, full width)

**Processing Flow:**
- Taps "PROCESS IMAGE" → `_processImage()`
- Shows loading spinner with "Processing Page..." text (animated fade loop)
- Calls `ApiService.processImage(imagePath, level)` → POST /api/v1/process (multipart)
- On success → navigates to `ResultScreen` with `sessionId`, `explanation`, `audioUrl`

---

### Screen 6: ResultScreen (result_screen.dart)
**What it does:** The core "Learning Space" — shows explanation + plays audio + enables Q&A
**Two Modes:**

**Mode A — Learning Space:**
- Glassmorphic card with scrollable explanation text (28px, white, 1.6 line height)
- Auto-plays TTS of explanation on load via `FlutterTts`
- **Audio Controls** (shown while playing):
  - Rewind (fast_rewind icon) — currently calls narrator "Rewound." (not fully functional)
  - Play/Pause (large blue circle button, 60px icon)
  - Forward (fast_forward icon) — narrator "Forwarded." (not fully functional)
- **Feedback Section** (shown after audio completes):
  - NarratorService: "Explanation finished. Tap left if it was too hard, middle if it was good, or right if it was too easy."
  - Three emoji buttons: 😖 Too Hard (red), 😊 Good (green), 🥱 Too Easy (blue)
  - Selecting any feedback → narrator confirms → returns to HomeScreen after 2 seconds
- **"Ask MARK" FAB** (purple): shown while explanation is playing → triggers chat mode

**Mode B — MARK Chat Space:**
- MARK avatar (cyan/amber gradient circle, graphic_eq icon) with pulse animation
- Status text: "MARK is thinking..." (amber) or "MARK is listening..." (cyan)
- Chat history as ListView with speech bubbles:
  - User messages: right-aligned, blue gradient bubble
  - MARK messages: left-aligned, slate gradient bubble
  - Each message has AccessibleWidget label for screen reader
- "Hold to Talk" button at bottom:
  - Long-press-start: turns red "Listening..." state, starts STT
  - Long-press-end: stops STT, calls `ApiService.askQuestion(sessionId, question, history)`
  - MARK's answer is spoken via NarratorService
- Back button returns to Learning Space

---

### Screen 7: HistoryScreen (history_screen.dart)
**What it does:** Shows list of past learning sessions
**Current State: MOCK DATA ONLY**
- Hardcoded 5 items: "Session 1-5", "Date: 2026-04-15 to 20", "Subject: Science"
- Each item is a glassmorphic card with history icon
- Staggered fadeIn animation (100ms delay per item)
- No real API integration — does not load from database yet
- Tapping items does nothing (no detail navigation)

---

### Screen 8: ProfileScreen (profile_screen.dart)
**What it does:** Displays current user info + logout
**Data source:** SharedPreferences (name, username stored at login)
- Profile avatar with blue-to-emerald gradient ring + glow shadow
- Name (36px, bold) + @username (22px, slate color)
- Glass card with:
  - "Account Details" row (tappable, no action)
  - "Accessibility Settings" row (tappable, no action)
- Red "LOG OUT" button → clears all SharedPreferences → navigates to LoginScreen
- NarratorService speaks "Profile screen. Logged in as [name]."

---

### Screen 9: SettingsScreen (settings_screen.dart)
**What it does:** App configuration options (partially implemented)
**Sections:**

**Accessibility:**
- High-Contrast Mode toggle (Switch) — `_highContrast` state managed locally, does NOT yet affect app theme
- Text Size setting — shows "Medium", no actual functionality

**Learning Preferences:**
- Explanation Mode — shows "Teen", no actual functionality

**Data Management:**
- Clear History button — no actual functionality

All settings are UI-only; none actually persist or change app behavior (except the visual state of the toggle).

---

## 5. BACKEND — FASTAPI ARCHITECTURE & EVERY ENDPOINT

**Base URL:** http://[HOST]:8000/api/v1
**Server:** Uvicorn ASGI (async capable)

### Startup Sequence
1. Loads `.env` (GEMINI_API_KEY, HF_API_TOKEN, POSTGRES_URL, REDIS_URL)
2. Connects to Redis (falls back to in-memory Python dict if Redis not available)
3. Creates `static/audio/` and `uploads/` directories if missing
4. SQLAlchemy `Base.metadata.create_all()` creates tables on startup
5. Mounts `/static` for serving audio files

---

### GET /
- Health check endpoint
- Returns: `{"message": "MATA Backend API is fully functional"}`

---

### POST /api/v1/register
- **Body (JSON):** `name, username, age, is_blind, email, mobile_no, password`
- **Process:**
  1. Checks if username OR email already exists in DB
  2. Hashes password with SHA-256 (`hashlib.sha256`)
  3. Creates new `User` record in database
  4. Returns `user_id`
- **Errors:** 400 if username/email duplicate

---

### POST /api/v1/login
- **Body (JSON):** `username, password`
- **Process:**
  1. Hashes password with SHA-256
  2. Queries DB for matching username + hash
  3. Returns user object (id, name, username, age, is_blind)
- **Errors:** 401 if invalid credentials

---

### POST /api/v1/process  ← THE CORE ENDPOINT
- **Body (multipart/form-data):** `file` (image), `age_level` (string)
- **Full AI Pipeline:**
  1. **UUID Session:** Generates unique `session_id` (UUID4)
  2. **Save Image:** Writes uploaded image to `uploads/` directory temporarily
  3. **OCR:** `OCRService.process_image()` → extracts text from image
  4. **VLM:** `VLMService.analyze_diagram()` → understands visual content
  5. **LLM:** `LLMService.generate_explanation(ocr_text, visual_text, age_level)` → generates explanation
  6. **TTS:** `TTSService.generate_audio(explanation)` → creates MP3 file → saves to `static/audio/`
  7. **Database Logging:** Creates `SessionLog` record with all data
  8. **Redis Caching:** Caches `{explanation, ocr_text, visual_text}` for 24 hours with `session_id` as key
  9. **Cleanup:** Deletes temp uploaded image
  10. **Returns:** `{session_id, ocr_text, layout, visuals, explanation, audio_url}`
- **Errors:** 500 with error message

---

### POST /api/v1/qa  ← THE Q&A ENDPOINT
- **Body (JSON):** `session_id, question, history (list of chat turns)`
- **Process:**
  1. **Context Retrieval:** Looks up `session_id` in Redis cache
  2. **DB Fallback:** If not in Redis → queries `SessionLog` table
  3. **LLM Q&A:** `LLMService.answer_question(question, context)` with rich prompt
  4. **TTS:** Generates audio for the answer
  5. **QA Logging:** Creates `QAHistory` record in DB
  6. **Returns:** `{answer, audio_url}`

---

## 6. AI PIPELINE — END-TO-END DATA FLOW

```
User captures image
        ↓
Flutter app → POST /api/v1/process (multipart)
        ↓
┌─────────────────────────────────────────────────────┐
│                   BACKEND AI PIPELINE               │
│                                                     │
│  1. Image Preprocessing (OpenCV):                   │
│     → Grayscale → Gaussian Blur (5×5) → Otsu        │
│       Thresholding → saves as _prep.jpg             │
│                                                     │
│  2. OCR Service (Primary: TrOCR via HF API):        │
│     → microsoft/trocr-base-printed                  │
│     → Sends preprocessed image to HF Inference API │
│     → Fallback: pytesseract (local Tesseract OCR)  │
│     → Returns: extracted text string                │
│                                                     │
│  3. VLM Service (Primary: Gemini 2.5 Flash):        │
│     → Base64 encodes original image                 │
│     → Sends to Google generativelanguage API        │
│     → Prompt: "Describe diagram in detail..."       │
│     → Fallback: HuggingFace BLIP captioning         │
│     → Returns: visual description string            │
│                                                     │
│  4. LLM Service (Primary: Gemini 2.5 Flash):        │
│     → Combines OCR text + visual description        │
│     → Applies age-level instruction in prompt       │
│     → Prompt: "You are MATA, an AI tutor..."        │
│     → Fallback: Meta Llama 3.3 70B via HF API      │
│     → Returns: educational explanation string       │
│                                                     │
│  5. TTS Service (gTTS):                             │
│     → gTTS(text, lang='en', slow=False)             │
│     → Saves as UUID.mp3 in static/audio/            │
│     → Returns: /static/audio/UUID.mp3 URL           │
│                                                     │
│  6. Data Storage:                                   │
│     → SQLite/PostgreSQL: SessionLog record          │
│     → Redis: JSON context (24-hour TTL)             │
└─────────────────────────────────────────────────────┘
        ↓
Response: {session_id, ocr_text, visuals, explanation, audio_url}
        ↓
Flutter ResultScreen:
→ Displays explanation text (28px, scrollable)
→ Plays audio via FlutterTts (local TTS on explanation text)
→ Note: audio_url from backend is received but ResultScreen
  uses local FlutterTts instead of streaming the server MP3
```

---

## 7. DATABASE SCHEMA

### Table: users
| Column | Type | Constraints |
|--------|------|------------|
| id | Integer | PK, autoincrement |
| name | String | — |
| username | String | UNIQUE, indexed |
| age | Integer | — |
| is_blind | String | 'yes' or 'no' |
| email | String | UNIQUE, indexed |
| mobile_no | String | — |
| password_hash | String | SHA-256 hash |
| created_at | DateTime | default: utcnow() |

### Table: sessions (SessionLog)
| Column | Type | Constraints |
|--------|------|------------|
| id | String | PK (UUID), indexed |
| timestamp | DateTime | default: utcnow() |
| age_level | String | 'child', 'teen', 'adult' |
| ocr_text | Text | Raw extracted text |
| visual_text | Text | VLM description |
| explanation | Text | LLM-generated explanation |

### Table: qa_history (QAHistory)
| Column | Type | Constraints |
|--------|------|------------|
| id | Integer | PK, autoincrement |
| session_id | String | indexed (FK reference) |
| timestamp | DateTime | default: utcnow() |
| question | Text | User's question |
| answer | Text | MARK's answer |

**Notes:**
- Default: SQLite file `mata_sessions.db` (local development)
- Production: PostgreSQL (set POSTGRES_URL env var)
- No explicit FK constraint between qa_history.session_id and sessions.id

---

## 8. ACCESSIBILITY SYSTEM (THE CORE DESIGN PHILOSOPHY)

MATA is built accessibility-first. Here is every accessibility feature implemented:

### AccessibleWidget (accessible_widget.dart)
**The central accessibility primitive used on EVERY interactive element.**

```dart
AccessibleWidget(
  label: "Descriptive text for screen reader",
  onActivate: () => someAction(),
  child: SomeVisualWidget(),
)
```

**Behavior:**
- **Single Tap:** Speaks `label` via NarratorService
- **Long Press:** Also speaks `label` (repeated for users who linger)
- **Double Tap:** Executes `onActivate` callback (the actual action)
- **Focus Change:** Speaks `label` when keyboard focus arrives
- **Semantics:** Wraps child in `Semantics(label, button: true)` → native screen reader compatible
- **Pattern:** Separates "exploration" (tap to hear) from "activation" (double-tap to act)

### NarratorService (narrator_service.dart)
**Singleton TTS screen reader throughout the entire app.**
- Uses `flutter_tts` package
- Language: `en-US`
- Speech rate: `0.5` (slower than default, optimized for comprehension)
- Volume: `1.0` (max)
- Pitch: `1.0` (neutral)
- Singleton pattern: one instance shared across all screens
- Used for: navigation announcements, action confirmations, error messages, post-playback prompts

### VoiceService (voice_service.dart)
**Singleton Speech-to-Text for voice commands.**
- Uses `speech_to_text` package
- Singleton: one shared instance
- `initSpeech()` → initializes STT engine
- `startListening(onResult)` → starts recognition, calls callback with recognized text
- `stopListening()` → stops recognition
- Used in: HomeScreen (voice navigation), ResultScreen (voice Q&A)

### Per-Screen Accessibility Announcements
| Screen | Announcement on Load |
|--------|---------------------|
| LoginScreen | "Welcome to your Textbook Assistant. Swipe right to explore profiles, or double-tap anywhere to log in as a new user." |
| HomeScreen | "Home screen. The main button to scan a page is in the center of your screen." |
| CameraScreen | "Camera open. Move your phone slightly higher. The bottom third of the screen is the capture button." |
| CameraScreen (2s delay) | "Edges detected. Hold still." + haptic vibration |
| ResultScreen (after audio) | "Explanation finished. Tap left if it was too hard, middle if it was good, or right if it was too easy." |
| ProfileScreen | "Profile screen. Logged in as [name]." |

### Haptic Feedback
- Camera screen initialization → `HapticFeedback.vibrate()` (edge detection simulation)
- Successful image capture → two `HapticFeedback.heavyImpact()` pulses with 200ms gap

### Visual Accessibility
- **Dark theme** throughout (reduces eye strain for low-vision users)
- **Large font sizes:** 22px minimum, 28–40px for primary content
- **High-contrast colors:** white text on dark backgrounds
- **Large touch targets:** minimum ~60px, most buttons 70–80px height
- **High-Contrast Mode toggle** in settings (state exists but not yet applied globally)

---

## 9. SERVICES — DETAILED BREAKDOWN

### OCRService (ocr_service.py)
**Primary:** Microsoft TrOCR (trocr-base-printed) via HuggingFace Inference API
- Transformer-based OCR trained on printed text
- Sends binary image bytes to HF API
- Returns `generated_text` from API response

**Preprocessing (always runs first):**
1. Read image with OpenCV (`cv2.IMREAD_COLOR`)
2. Convert to grayscale
3. Apply Gaussian blur (5×5 kernel) — removes noise
4. Otsu's binarization (adaptive threshold) — creates clean black/white
5. Saves preprocessed image as `{original}_prep.{ext}`
6. Processes preprocessed image through OCR
7. Cleans up preprocessed file after OCR

**Fallback:** pytesseract (local Tesseract OCR) — used when HF token missing or API fails

---

### VLMService (vlm_service.py)
**Primary:** Google Gemini 2.5 Flash (v1beta endpoint)
- Base64-encodes the image
- Sends to `generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash`
- Prompt: "Describe this diagram or image in detail. Be educational and precise. If it's a technical diagram, explain the components. If it's just text, say 'No diagram present.'"
- Returns text description of visual content

**Fallback:** Salesforce BLIP (blip-image-captioning-base) via HuggingFace InferenceClient
- `client.image_to_text(image_bytes, model=hf_model_id)`
- Returns caption string prefixed with "[HF Fallback]"

---

### LLMService (llm_service.py)
**Primary:** Google Gemini 2.5 Flash
- Temperature: 0.6 (balanced creativity/accuracy)
- Two distinct methods:

**`generate_explanation(ocr_text, visual_text, age_level)`:**
Age-level instructions:
- Child: "Use simple vocabulary suitable for a 10-year-old child. Use analogies and simple examples."
- Teen: "Use standard educational vocabulary for a high school student. Include technical terms."
- Adult: "Use full technical content and formal language for a college student."

Prompt: "You are MATA, an expert AI tutor. Explain the following textbook content. [instruction] Only output the explanation, no extra conversational text. Text extracted: [ocr_text] Visual descriptions: [visual_text] Explain this content."

**`answer_question(question, context)`:**
Prompt: "You are MATA, an AI tutor. Answer strictly based on the following textbook context: [context] If unrelated, say 'That question doesn't seem to be about this page. Want me to answer anyway?' Question: [question]"

**Fallback:** Meta Llama 3.3 70B Instruct via HuggingFace InferenceClient
- `client.chat_completion(model, messages, max_tokens=500)`

---

### TTSService (tts_service.py)
**Engine:** gTTS (Google Text-to-Speech)
- Language: English
- Speed: Normal (slow=False)
- Saves to `static/audio/{UUID}.mp3`
- Returns URL path `/static/audio/{UUID}.mp3`
- Comment in code acknowledges this is a placeholder; Coqui TTS was intended for neural voice

---

## 10. CONFIGURATION & ENVIRONMENT

### .env (MATA-Backend/.env)
```
HF_API_TOKEN=your_hf_token_here    # HuggingFace API
GEMINI_API_KEY=your_gemini_key_here  # Google Gemini
POSTGRES_URL=                                            # Empty → uses SQLite
REDIS_URL=                                               # Empty → uses dict fallback
```

### API Base URL (api_service.dart)
```dart
static const String baseUrl = 'http://192.168.0.100:8000/api/v1';
```
- Hardcoded to a local IP address (192.168.0.100)
- Comment says "Using ADB Reverse Tunneling for Wireless Device Connectivity"
- This must be changed for any deployment

### mark/ folder (e:\MARK\mark\)
- Completely separate Flutter project
- Just the default Flutter counter demo app
- **Not part of MATA at all** — appears to be an empty boilerplate project created accidentally or for testing

---

## 11. FEATURES IMPLEMENTED (COMPLETE LIST)

### Authentication & User Management
- [x] User registration with full profile (name, username, age, email, mobile, password, blindness status)
- [x] SHA-256 password hashing
- [x] Username/email uniqueness validation
- [x] User login with credential verification
- [x] Session persistence via SharedPreferences (stays logged in across app restarts)
- [x] Guest mode (skip auth entirely)
- [x] Logout (clears SharedPreferences)

### Core Scanning & AI Pipeline
- [x] Live camera capture (back camera, high resolution)
- [x] Haptic feedback on capture (two heavyImpact pulses)
- [x] Image upload to backend (multipart/form-data)
- [x] Image preprocessing (grayscale → blur → Otsu binarization)
- [x] OCR text extraction (TrOCR primary, Tesseract fallback)
- [x] Visual diagram analysis (Gemini 2.5 Flash primary, BLIP fallback)
- [x] Age-adaptive LLM explanation (Child/Teen/Adult modes)
- [x] Server-side TTS audio generation (gTTS → MP3)
- [x] Session caching in Redis (24h TTL)
- [x] Session + Q&A logging in database

### Learning Space (Result Screen)
- [x] Explanation text display (large font, scrollable)
- [x] Auto-play TTS of explanation (local FlutterTts)
- [x] Play/Pause audio control
- [x] Explanation completion detection
- [x] Post-explanation feedback (😖/😊/🥱 emoji buttons)
- [x] Feedback → returns to home after 2 seconds

### MARK Q&A Bot
- [x] Voice Q&A (hold-to-talk → release-to-send)
- [x] Context-aware answers (session context from Redis/DB)
- [x] Chat history display (speech bubbles, user/bot sides)
- [x] Bot "thinking" vs "listening" state animation
- [x] TTS readback of MARK's answers via NarratorService

### Accessibility
- [x] Custom AccessibleWidget (tap=read, double-tap=activate, focus=read)
- [x] Built-in NarratorService screen reader (per-screen announcements)
- [x] VoiceService STT integration
- [x] Haptic feedback (vibration on camera ready + capture)
- [x] Large fonts (22–40px throughout)
- [x] Large touch targets (60–80px+)
- [x] Dark high-contrast theme
- [x] Semantics labels on all interactive elements
- [x] Blind user flag in registration and DB

### Navigation & Architecture
- [x] Bottom navigation bar (4 tabs: Scan, History, Profile, Settings)
- [x] Route-based navigation (push/pop/replacement)
- [x] Singleton services (NarratorService, VoiceService)
- [x] Glassmorphism UI (BackdropFilter + gradient overlays)
- [x] Flutter animations (flutter_animate: fadeIn, slideY, slideX, scaleXY)
- [x] Radial gradient backgrounds per screen

### Backend Infrastructure
- [x] FastAPI REST API (versioned: /api/v1/)
- [x] SQLite fallback database
- [x] PostgreSQL support (via env var)
- [x] Redis caching with dict fallback
- [x] Static file serving (audio MP3s)
- [x] Automatic directory creation on startup
- [x] CORS-compatible (FastAPI defaults)

---

## 12. WHAT IS NOT YET IMPLEMENTED (GAPS)

> Last audited: May 2026 — based on full source analysis of all 24+ files.

---

### History Screen
- ✅ ~~Real API call — shows 5 hardcoded mock entries~~ — Now calls `GET /api/v1/sessions`
- ✅ ~~Clicking a history item — does nothing~~ — Double-tap opens `ResultScreen` with full session
- ✅ ~~Re-entering a past learning session~~ — Loads `explanation`, `audio_url`, and `chat_history`
- ✅ ~~Deleting history items~~ — Swipe-to-dismiss calls `DELETE /api/v1/sessions/{id}`
- ❌ Session title/subject label — still hardcoded as `"Session"` (no subject auto-detection)
- ❌ Pagination — only shows the last 20 sessions (no "load more")
- ❌ Search/filter history by date or topic

---

### Settings Screen
- ✅ ~~Explanation Mode setting not persisting~~ — Persisted via `SettingsProvider` + `SharedPreferences`; pre-selected in `ConfigurationScreen`
- ✅ ~~Clear History not working~~ — Calls `DELETE /api/v1/sessions` which wipes both `sessions` and `qa_history` tables
- ✅ ~~Text Size not persisting~~ — Saved and loaded via `SettingsProvider`
- ✅ ~~High-Contrast Mode not persisting~~ — Saved and loaded via `SettingsProvider`
- ❌ **High-Contrast Mode not applied to UI** — Toggle saves the value but no `MaterialApp` theme rebuild reads it; app colors do not change
- ❌ **Text Size not applied to UI** — `textSize` multiplier is stored in provider but no widget uses `MediaQuery.textScaleFactor` or reads it for font scaling
- ❌ Server IP setting — `ApiService.updateServerIp()` exists but there is no UI field in `SettingsScreen` to change it

---

### Profile Screen
- ✅ ~~"Account Details" row — no action~~ — Edit dialog now allows name, age, and blind/low-vision flag updates
- ✅ ~~"Accessibility Settings" row — no action~~ — Navigates to `SettingsScreen`
- ✅ ~~Editing profile information~~ — Calls `PUT /api/v1/profile` and updates `SharedPreferences`
- ✅ ~~Profile picture upload~~ — Calls `POST /api/v1/profile/picture` via `ImagePicker`
- ❌ Profile picture **displayed from server URL** — uploaded URL is saved but the UI shows a local `AssetImage` fallback, not the network image
- ❌ Profile data loaded from server — currently loaded from `SharedPreferences` only; no `GET /api/v1/profile` endpoint exists
- ❌ Accessibility Settings row still navigates generically; no per-user backend sync

---

### Camera / Upload
- ✅ ~~Gallery image upload not integrated~~ — `ImagePicker` wired in `HomeScreen`; opens `ConfigurationScreen`
- ✅ ~~PDF upload not integrated~~ — `FilePicker` wired in `HomeScreen`; opens `ConfigurationScreen` with `isPdf: true`
- ✅ ~~Camera flash toggle~~ — Implemented in `CameraScreen`
- ✅ ~~Front/back camera switch~~ — Implemented in `CameraScreen`
- ✅ ~~Edge detection simulation~~ — Replaced with real `google_mlkit_document_scanner` for auto-scan
- ❌ **Multi-page scan session** — Backend `/api/v1/process_images_batch` exists but no Flutter UI exposes multi-page scanning
- ❌ **Zoom control** — No pinch-to-zoom or zoom slider in `CameraScreen`
- ❌ **Image preview before processing** — After capture, image goes straight to `ConfigurationScreen`; no crop/review step

---

### Audio
- ✅ ~~Real audio streaming from server~~ — `audioplayers` plays the MP3 URL returned from `edge-tts` (neural voice)
- ✅ ~~Rewind 10 seconds~~ — `_seekAudio(-10)` implemented with `_audioPlayer.seek()`
- ✅ ~~Forward 10 seconds~~ — `_seekAudio(10)` implemented with `_audioPlayer.seek()`
- ✅ ~~Playback speed control~~ — 1x / 1.5x / 2x toggle implemented via `_audioPlayer.setPlaybackRate()`
- ✅ ~~Neural voice (gTTS)~~ — Backend now uses `edge-tts` (`en-US-ChristopherNeural`) for high-quality neural voice
- ❌ **Audio seek on TTS fallback** — If `audioplayers` fails and falls back to `FlutterTts`, rewind/forward buttons narrate but do not actually seek (FlutterTts has no seek API)
- ❌ **QA answer audio not played** — `/api/v1/qa` returns `audio_url` for each answer, but `ResultScreen` does not play it; only the narrator speaks a text-stripped version
- ❌ **Audio progress indicator** — No visual progress bar / timestamp shown while audio plays
- ❌ **Background audio** — Audio stops when app goes to background or screen locks

---

### Voice Assistant / Narrator
- ✅ ~~Reads Markdown symbols~~ — Markdown stripped before narrator speaks
- ✅ ~~Reads LaTeX `$` symbols~~ — LaTeX stripped before narrator speaks
- ✅ ~~Restarts when screen is touched~~ — Fixed; `onTap` (not `onPointerDown`), and duplicate-text guard added to `NarratorService`
- ❌ **Mathematical equations narrated as symbols** — LaTeX like `\frac{a}{b}` or `\alpha^2` is stripped to empty text rather than read as "a over b" or "alpha squared"; proper math-to-speech conversion is not implemented
- ❌ **"Hey MARK" wake-word** — No always-on microphone; requires manual button press
- ❌ **Screen-reader interop** — `Semantics` labels are set but not tested with TalkBack / VoiceOver; focus order may be incorrect
- ❌ **Earcons / audio icons** — No non-speech sound cues for events (capture success, navigation, errors)

---

### MARK Bot (Q&A)
- ✅ ~~Text input for Q&A~~ — `TextField` and mic button both wired in `ResultScreen`
- ✅ ~~Chat history persistence across sessions~~ — QA stored in `qa_history` table; reloaded in `HistoryScreen`
- ✅ ~~Markdown + LaTeX rendered in chat bubbles~~ — `flutter_markdown` + `flutter_math_fork` integrated
- ❌ **"Hey MARK" wake-word during chat** — Not implemented
- ❌ **Conversation context window** — Full `_chatHistory` list sent every request; no trimming for very long sessions (token overflow risk)
- ❌ **Typing indicator animation** — `_isBotThinking` state variable exists but no animated typing dots in UI

---

### Authentication
- ✅ ~~JWT tokens for secure sessions~~ — JWT issued on login, sent as `Authorization: Bearer` header on all protected routes
- ✅ ~~Bcrypt password hashing~~ — Backend uses `passlib[bcrypt]`; old SHA-256 hashes are silently upgraded on login
- ❌ **"Forgot password" flow** — Not implemented (no password reset endpoint or email delivery)
- ❌ **Email verification on registration** — No email confirmation step
- ❌ **OAuth (Google/Apple sign-in)** — Not implemented
- ❌ **JWT refresh tokens** — Access token expires (configurable via env), but no refresh token logic; user must log in again
- ❌ **`flutter_secure_storage` not used** — JWT token stored in unencrypted `SharedPreferences` despite the package being in `pubspec.yaml`
- ❌ **Token expiry handling** — No automatic 401 → redirect-to-login logic in `ApiService`

---

### Backend
- ✅ ~~Rate limiting on API endpoints~~ — `slowapi` applied with `5/minute` on process routes, `20/minute` on QA
- ✅ ~~File size validation on uploads~~ — `validate_file_size` Depends utility applied (5 MB for images, 15 MB for PDFs)
- ✅ ~~Proper JWT authentication middleware~~ — `get_current_user` dependency on all authenticated routes
- ✅ ~~CORS configuration~~ — `CORSMiddleware` with `ALLOWED_ORIGINS` env var (defaults to localhost)
- ✅ ~~PDF parsing pipeline~~ — `PyMuPDF (fitz)` via `parse_pdf()` in `utils.py`
- ✅ ~~Multi-page scanning session~~ — `POST /api/v1/process_images_batch` endpoint implemented
- ❌ **`GET /api/v1/profile` endpoint missing** — Profile data cannot be fetched from server; Flutter reads from local `SharedPreferences` only
- ❌ **Sessions not scoped to logged-in user** — `GET /api/v1/sessions` returns **all** sessions in DB, not just the current user's; no `user_id` column in `SessionLog`
- ❌ **Duplicate `/api/v1/profile/picture` routes** — Two endpoints exist (`POST /api/v1/profile/picture` and `POST /api/v1/profile/upload_picture`); the second one stores a local path, not a URL
- ❌ **TrOCR API timeout too short** — `timeout=5` seconds in `ocr_service.py`; HuggingFace cold-start takes 15–30 seconds, causing frequent fallback to Tesseract
- ❌ **LLM API URL incorrect** — `llm_service.py` calls `gemini-3.5-flash` but the real model name is `gemini-1.5-flash` (version naming mismatch)
- ❌ **Input validation on registration** — No email format check, no password strength enforcement, no mobile number format validation
- ❌ **Feedback endpoint missing** — `_provideFeedback()` in `ResultScreen` only plays a narrator message; no `POST /api/v1/feedback` endpoint exists to persist ratings

---

### Infrastructure
- ✅ ~~Error monitoring~~ — Sentry SDK initialized if `SENTRY_DSN` env var is set
- ✅ ~~Audio file cleanup~~ — `cleanup_audio_files()` runs as `BackgroundTask` after each process request (deletes files older than 1 day)
- ✅ ~~Request timeout handling in Flutter~~ — All `ApiService` calls have a 90-second `timeoutDuration`
- ✅ ~~API key rotation~~ — Multiple Gemini keys rotate on failure in `llm_service.py` and `vlm_service.py`
- ❌ **API keys hardcoded in `.env` committed to repo** — Real Gemini keys and HF tokens are visible in version control; must be rotated and added to `.gitignore`
- ❌ **Redis URL blank in `.env`** — `REDIS_URL` is empty; server falls back to in-memory dict on every restart, losing all cached session context
- ❌ **No `.gitignore` for `.env`** — Secrets file appears to be tracked by git
- ❌ **No HTTPS / TLS** — Backend runs on plain HTTP; all tokens and data transmitted unencrypted on the network
- ❌ **`mark/` boilerplate folder** — Contains untouched default Flutter counter app; adds confusion and should be removed

---

## 13. SUGGESTIONS — NEW FEATURES TO ADD

### Priority 1 — Complete Existing Features
1. **Apply High-Contrast & Text Size settings** — Read `SettingsProvider` values in `MaterialApp` theme and use `textScaleFactor` globally
2. **Scope sessions to logged-in user** — Add `user_id` FK to `SessionLog`; filter `/api/v1/sessions` by the authenticated user
3. **Add `GET /api/v1/profile` endpoint** — Return current user's full profile so Flutter can sync from server on login
4. **Fix LLM API model name** — Change `gemini-3.5-flash` → `gemini-1.5-flash` in both `llm_service.py` and `vlm_service.py`
5. **Play QA answer audio** — Wire the `audio_url` returned by `/api/v1/qa` into the `AudioPlayer` in `ResultScreen`

### Priority 2 — Core Improvements
6. **Math-to-speech conversion** — Convert LaTeX tokens to spoken words before TTS (e.g., `\frac{a}{b}` → "a over b"); use a regex/dictionary approach in `tts_service.py`
7. **JWT refresh token** — Add refresh endpoint; Flutter auto-renews token on 401 response
8. **Streaming API responses** — Stream LLM output via SSE so explanation appears progressively in the Learning Space
9. **Multi-language support** — Prompt LLM in the user's preferred language; switch `edge-tts` voice accordingly
10. **Audio progress bar** — Show a scrubable slider in `ResultScreen` tied to `_audioPlayer` position stream

### Priority 3 — New Screens & Features
11. **Bookmarks / Favorites** — Tag specific sessions; filter history by bookmarked
12. **Flashcard Generator** — MARK auto-generates 3–5 study flashcards after each explanation
13. **Quiz Mode** — MARK poses comprehension questions; tracks score per session
14. **Progress Dashboard** — Weekly stats: pages scanned, subjects, quiz accuracy, streak
15. **Offline Mode** — Cache last 5 sessions locally; use local Tesseract when no internet

### Priority 4 — Advanced AI Features
16. **"Hey MARK" wake word** — Always-on microphone using Porcupine SDK or on-device ML Kit
17. **Personalized Learning Path** — Track "Too Hard" feedback; reinforce weak topics in future sessions
18. **Subject Auto-Detection** — LLM tags sessions with subject (Math, Science, History) for better history labels
19. **Camera Guidance** — Real-time audio: "Tilt left", "Move closer", "Hold still" using image analysis during capture
20. **Video Explanation Mode** — Generate short animated text+graphics explainers for complex topics

---

## 14. SUGGESTIONS — ADVANCEMENTS FOR VISUALLY IMPAIRED USERS

### Immediate Improvements
1. **Wake Word Detection ("Hey MARK")** — Always-on microphone listening using on-device ML Kit or Porcupine SDK
2. **Haptic Alphabet/Language** — Vibration patterns: short pulse = new paragraph, long = page end, double = MARK has a question
3. **Earcons (Audio Icons)** — Distinct non-speech sound cues: chime when app ready, beep on capture, whoosh on navigation
4. **Swipe Navigation Schema** — Full gesture-only operation: swipe left/right = tabs, swipe up = scan, swipe down = history
5. **Spatial Audio Layout** — Main button audio from center, MARK responses from bottom-right

### Deep Accessibility Features
6. **Braille Display Support** — Bluetooth to refreshable Braille display; push explanation in BRF format
7. **Enhanced Screen Reader** — Replace basic `NarratorService` with context announcements: "Button 1 of 3", "You are on the Scan tab"
8. **Voice-First Complete Mode** — Entire app controlled by voice commands after "Hey MARK"; no touch needed
9. **Camera Guidance System** — Real-time audio: "Tilt left a little", "Move closer", "Good! Page aligned. Hold still."
10. **Document Distance Detection** — Use sensors to detect camera distance from page; narrate optimal distance

### Learning & Comprehension Support
11. **Reading Speed Adaptation** — Learn preferred TTS speed; start slow and accept "faster" voice command
12. **Comprehension Check Questions** — After each paragraph MARK asks one question; re-explains on wrong answer
13. **Emotional Tone Detection** — If user sounds frustrated, MARK switches to simpler, encouraging style
14. **Persistent Audio Bookmarks** — "MARK, bookmark this" creates audio note at that page position
15. **Multi-Speed Playback with Skip** — "MARK, repeat that", "skip this section", "read slower" voice commands

### Navigation & Orientation
16. **App Tutorial Mode** — First-time narrated walkthrough of every gesture; replayable from Settings
17. **Shortcut Gestures** — Three-finger tap = home, three-finger swipe up = scan, two-finger circle = invoke MARK
18. **Context Awareness** — Announce remaining audio time: "2 minutes of explanation remaining"
19. **Battery & Network Status Narration** — "Low battery: 15%" or "Weak signal - processing may be slow" announced proactively
20. **Emergency Contact** — If user is stuck 30 seconds, MARK asks "Do you need help?" and offers to call a saved contact

### Social & Support Features
21. **Family/Caregiver Mode** — Simplified interface; larger fonts (40px+), fewer options, everything narrated
22. **Class Sharing** — Generate shareable audio explanation link; share via WhatsApp/email
23. **Customizable Voice** — Choose from 3–5 MARK voice options (gender, speed, accent)
24. **Hands-Free Mode** — Auto-capture when phone held steady for 3 seconds
25. **Night-Mode TTS Only** — Silent visual + earphone-only mode for library/classroom

---

## 15. KNOWN ISSUES & TECHNICAL DEBT

| # | Issue | Severity | Status |
|---|-------|----------|--------|
| 1 | **API keys in `.env` committed to repo** — Real Gemini & HF keys are visible in version control | 🔴 Critical | ❌ Open |
| 2 | **Hardcoded IP in `api_service.dart`** — `192.168.0.101:8000` breaks on any other network | 🔴 Critical | ❌ Open |
| 3 | **No HTTPS** — All tokens and data sent over plain HTTP | 🔴 Critical | ❌ Open |
| 4 | **Sessions not user-scoped** — All users see all sessions in history | 🔴 Critical | ❌ Open |
| 5 | **JWT stored in unencrypted SharedPreferences** — `flutter_secure_storage` unused despite being in pubspec | 🟠 High | ❌ Open |
| 6 | **No token expiry / refresh flow** — Users silently fail on expired tokens | 🟠 High | ❌ Open |
| 7 | **LLM model name mismatch** — `gemini-3.5-flash` doesn't exist; correct name is `gemini-1.5-flash` | 🟠 High | ❌ Open |
| 8 | **TrOCR timeout 5s** — HuggingFace cold-starts take 15–30s; always falls back to Tesseract | 🟠 High | ❌ Open |
| 9 | **Duplicate profile picture routes** — Two endpoints (`/profile/picture` and `/profile/upload_picture`) with different behavior | 🟡 Medium | ❌ Open |
| 10 | **No `GET /api/v1/profile`** — Profile only read from `SharedPreferences`; server-side data not synced | 🟡 Medium | ❌ Open |
| 11 | **High-Contrast & Text Size settings not applied to UI** — Values saved but no widgets read them | 🟡 Medium | ❌ Open |
| 12 | **QA answer audio not played** — `audio_url` from `/api/v1/qa` is returned but ignored by Flutter | 🟡 Medium | ❌ Open |
| 13 | **Redis URL empty** — Falls back to in-memory dict; session context lost on every restart | 🟡 Medium | ❌ Open |
| 14 | **No feedback persistence** — `_provideFeedback()` plays narrator but no backend endpoint stores ratings | 🟡 Medium | ❌ Open |
| 15 | **Math-to-speech not implemented** — LaTeX stripped to empty string before TTS; equations are skipped entirely | 🟡 Medium | ❌ Open |
| 16 | **No input validation on RegisterScreen** — No email format, password strength, or required-field checks | 🟡 Medium | ❌ Open |
| 17 | **Audio seek unavailable on TTS fallback** — Rewind/Forward only work with `audioplayers`; FlutterTts has no seek API | 🟡 Medium | ❌ Open |
| 18 | **Conversation context not trimmed** — Full chat history sent on every QA request; long sessions risk LLM token overflow | 🟡 Medium | ❌ Open |
| 19 | **`mark/` boilerplate folder** — Default Flutter counter app committed; creates confusion | 🟢 Low | ❌ Open |
| 20 | **`is_blind` stored as 'yes'/'no' string** — Should be a boolean in DB schema | 🟢 Low | ❌ Open |
| 21 | **Session title always "Session"** — No subject auto-detection; history list has no meaningful labels | 🟢 Low | ❌ Open |
| 22 | **No audio progress bar** — No visual scrubber or timestamp while audio plays | 🟢 Low | ❌ Open |

---

*Document updated: May 2026 — Full re-audit of all 26 source files across Flutter (Dart) and Python (FastAPI)*  
*Files analysed: `main.dart`, `home_screen.dart`, `camera_screen.dart`, `configuration_screen.dart`, `result_screen.dart`, `history_screen.dart`, `settings_screen.dart`, `profile_screen.dart`, `login_screen.dart`, `register_screen.dart`, `api_service.dart`, `narrator_service.dart`, `voice_service.dart`, `accessible_widget.dart`, `markdown_math.dart`, `settings_provider.dart`, `main.py`, `database.py`, `auth.py`, `utils.py`, `llm_service.py`, `ocr_service.py`, `vlm_service.py`, `tts_service.py`*
ute force.
4. **No CORS configuration** — FastAPI allows all origins by default; should be restricted in production.
5. **Audio file accumulation** — `static/audio/` MP3 files are never cleaned up; disk will fill up over time.
6. **mark/ folder** — Contains default Flutter boilerplate with no relation to MATA; should be removed or clearly marked.
7. **Settings not persisting** — All settings are ephemeral in-memory state only.
8. **History not connected** — HistoryScreen shows hardcoded data.
9. **No request timeout** — HTTP calls in api_service.dart have no timeout; app will hang on slow servers.
10. **TrOCR API limitations** — HuggingFace free tier has rate limits; needs better error handling and retry logic.
11. **Flutter secure_storage not used** — It's in pubspec but SharedPreferences (unencrypted) is used for sensitive user_id.
12. **Missing input validation** — No form validation in RegisterScreen (email format, password strength, required fields).
13. **`is_blind` as string** — Should be a boolean; stored as 'yes'/'no' string.
14. **Rewind/Forward buttons** — UI exists but functionality is only a narrator announcement (not real seek).

---

*Document generated by automated analysis of E:\MARK codebase — May 2026*
*Total files analyzed: 24 source files across Flutter (Dart) and Python (FastAPI)*
