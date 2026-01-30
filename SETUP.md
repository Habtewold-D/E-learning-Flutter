# Setup Instructions

## Backend Setup

1. **Create virtual environment:**
```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. **Install dependencies:**
```bash
pip install -r requirements.txt
```

3. **Setup environment variables:**
```bash
cp .env.example .env
# Edit .env with your database URL and OpenAI API key
```

4. **Initialize database:**
```bash
# Make sure PostgreSQL is running and database exists
python init_db.py
```

5. **Run the server:**
```bash
uvicorn app.main:app --reload
```

The API will be available at `http://localhost:8000`
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## Mobile Setup

1. **Install Flutter dependencies:**
```bash
cd mobile
flutter pub get
```

2. **Update API base URL:**
Edit `lib/core/utils/constants.dart` and change the `baseUrl` to match your backend:
- For Android Emulator: `http://10.0.2.2:8000/api`
- For iOS Simulator: `http://localhost:8000/api`
- For Physical Device: `http://YOUR_IP:8000/api`

3. **Run the app:**
```bash
flutter run
```

## Database Setup (PostgreSQL)

If you don't have PostgreSQL installed:

1. **Install PostgreSQL:**
```bash
# Ubuntu/Debian
sudo apt-get install postgresql postgresql-contrib

# macOS
brew install postgresql

# Windows: Download from postgresql.org
```

2. **Create database:**
```bash
sudo -u postgres psql
CREATE DATABASE elearning_db;
CREATE USER your_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE elearning_db TO your_user;
\q
```

3. **Update .env file:**
```
DATABASE_URL=postgresql://your_user:your_password@localhost:5432/elearning_db
```

## Quick Start (SQLite - Development Only)

For quick testing without PostgreSQL, you can use SQLite:

1. **Update `backend/app/core/database.py`:**
```python
DATABASE_URL = "sqlite:///./elearning.db"
```

2. **Update `backend/app/core/config.py`:**
```python
DATABASE_URL: str = "sqlite:///./elearning.db"
```

Note: SQLite is not recommended for production, especially with concurrent writes.

## Testing the API

1. **Register a teacher:**
```bash
curl -X POST "http://localhost:8000/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Teacher",
    "email": "teacher@example.com",
    "password": "password123",
    "role": "teacher"
  }'
```

2. **Login:**
```bash
curl -X POST "http://localhost:8000/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "teacher@example.com",
    "password": "password123"
  }'
```

3. **Create a course (use the token from login):**
```bash
curl -X POST "http://localhost:8000/api/courses/" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Introduction to Python",
    "description": "Learn Python programming"
  }'
```

## Troubleshooting

### Backend Issues

- **Database connection error:** Check PostgreSQL is running and DATABASE_URL is correct
- **Import errors:** Make sure you're in the virtual environment
- **Port already in use:** Change PORT in .env or kill the process using port 8000

### Mobile Issues

- **Connection refused:** Update baseUrl in api_client.dart to match your setup
- **Build errors:** Run `flutter clean` and `flutter pub get`
- **iOS/Android specific:** Check platform-specific setup in Flutter docs

## Next Steps

1. Test all API endpoints using Swagger UI
2. Test mobile app authentication
3. Upload a PDF and test RAG functionality
4. Create an exam and test grading
5. Test live class room creation

