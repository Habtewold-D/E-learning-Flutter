# E-Learning Platform MVP

A comprehensive e-learning platform built with Flutter (mobile) and FastAPI (backend), featuring live classes, course management, and exams.

## 🎯 Project Overview

This is an MVP (Minimum Viable Product) designed to demonstrate:
- ✅ Live teaching capabilities
- ✅ Course upload (video + PDF)
- ✅ Exam creation and auto-grading
- ✅ Clean architecture with modern tech stack

## 🏗️ Architecture

```
Flutter Mobile App
      |
      | REST API
      |
FastAPI Backend
 ├── Auth Service (JWT)
 ├── Course Service
 ├── Exam Service
 ├── Live Class Service
 |
PostgreSQL Database
 |
File Storage (Local/Cloud)
```

## 🛠️ Technology Stack

### Frontend (Flutter)
- **Core**: Flutter, Dio, Riverpod
- **Media**: video_player, file_picker, syncfusion_flutter_pdfviewer
- **Live Class**: jitsi_meet_flutter_sdk
- **Storage**: flutter_secure_storage

### Backend (FastAPI)
- **Core**: FastAPI, SQLAlchemy, Pydantic, Python-JOSE, Passlib
- **Database**: PostgreSQL
- **Storage**: Local filesystem (can be upgraded to S3/Cloudinary)

## 📁 Project Structure

```
biruk_challenge/
├── backend/                 # FastAPI backend
│   ├── app/
│   │   ├── api/
│   │   │   ├── auth.py
│   │   │   ├── courses.py
│   │   │   ├── exams.py
│   │   │   └── live.py
│   │   ├── core/
│   │   │   ├── config.py
│   │   │   ├── security.py
│   │   │   └── database.py
│   │   ├── models/
│   │   ├── schemas/
│   │   ├── services/
│   │   │   └── file_service.py
│   │   └── main.py
│   ├── requirements.txt
│   └── .env.example
├── mobile/                  # Flutter app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   ├── courses/
│   │   │   ├── exams/
│   │   │   └── live/
│   │   └── providers/
│   ├── pubspec.yaml
│   └── README.md
└── README.md
```

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

## 📅 Development Timeline (1 Week)

- **Day 1**: Project setup + Authentication
- **Day 2**: Course management + File uploads
- **Day 3**: Exam system + Auto-grading
- **Day 4**: Live class integration
- **Day 5**: Integration + UI polish
- **Day 6**: Testing + Documentation

## 🔑 Environment Variables

### Backend (.env)
```
DATABASE_URL=postgresql://user:password@localhost/dbname
SECRET_KEY=your-secret-key
ALGORITHM=HS256
UPLOAD_DIR=./uploads
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

