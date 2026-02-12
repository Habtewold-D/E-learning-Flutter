
# E-Learning Platform MVP

A modern e-learning platform with a Flutter mobile app and FastAPI backend, supporting live classes, course management, exams, and AI-powered search (RAG).

## 🚀 Features

**Teacher:**
- Register/Login
- Create and manage courses
- Upload videos and PDFs
- Create and auto-grade MCQ exams
- View student results
- Start live classes (Jitsi)

**Student:**
- Register/Login
- Browse and enroll in courses
- Watch videos and read PDFs
- Take exams and view grades
- Join live classes

**AI & RAG:**
- Semantic search over course content (PDFs)
- AI-powered question answering (Groq)
- Fast, memory-efficient vector search (ChromaDB)

**Other:**
- JWT authentication
- Secure file uploads
- Cloudinary and local storage support
- Push notifications (Firebase)

## 🛠️ Technology Stack

- **Frontend:** Flutter, Riverpod, Dio, Jitsi SDK, video_player, file_picker
- **Backend:** FastAPI, SQLAlchemy, Pydantic, ChromaDB, Sentence Transformers, Groq, PostgreSQL
- **Storage:** Local filesystem, Cloudinary
- **Notifications:** Firebase Cloud Messaging

## 🔑 Backend Environment Variables

Set these in `backend/.env` (see `.env.example` for template):

```
# Database
DATABASE_URL

# Security
SECRET_KEY
ALGORITHM
ACCESS_TOKEN_EXPIRE_MINUTES

# File Storage
UPLOAD_DIR
MAX_FILE_SIZE_MB

# Cloudinary (optional)
CLOUDINARY_CLOUD_NAME
CLOUDINARY_API_KEY
CLOUDINARY_API_SECRET

# Server
HOST
PORT

# JaaS (Jitsi as a Service, for live classes)
JAAS_APP_ID
JAAS_API_KEY
JAAS_PRIVATE_KEY

# Firebase (Push notifications)
FIREBASE_SERVICE_ACCOUNT_JSON

# RAG / AI
GROQ_API_KEY
```

## ⚡ Quick Start

### Backend
```bash
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env  # Edit .env with your values
uvicorn app.main:app --reload
```

### Mobile
```bash
cd mobile
flutter pub get
flutter run
```

## 📚 API Docs

Once the backend is running:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## 📄 License

MIT License

## 🚀 Quick Start

### Backend Setup
```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env
# Edit .env with your database and API keys
uvicorn app.main:app --reload
```

### Mobile Setup
```bash
cd mobile
flutter pub get
flutter run
```

## 🔑 Environment Variables

### Backend (.env)
```
DATABASE_URL=postgresql://user:password@localhost/dbname
SECRET_KEY=your-secret-key
ALGORITHM=HS256
```

## 📝 Features

### Teacher
- Login/Register
- Create and manage courses
- Upload videos and PDFs
- Create MCQ exams
- View student results
- Start live classes

### Student
- Login/Register
- Browse and enroll in courses
- Watch videos / Read PDFs
- Take exams
- View grades

## 🔒 Security

- JWT-based authentication
- Password hashing with bcrypt
- Secure file upload validation
- CORS configuration

## 📚 API Documentation

Once the server is running, visit:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## 📄 License

MIT License

