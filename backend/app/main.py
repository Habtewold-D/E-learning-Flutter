from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.api import auth, courses, exams, rag, live

app = FastAPI(
    title="E-Learning Platform API",
    description="Backend API for e-learning platform with RAG capabilities",
    version="1.0.0"
)

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify exact origins (e.g., ["http://localhost:3000"])
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])
app.include_router(courses.router, prefix="/api/courses", tags=["Courses"])
app.include_router(exams.router, prefix="/api/exams", tags=["Exams"])
app.include_router(rag.router, prefix="/api/rag", tags=["RAG"])
app.include_router(live.router, prefix="/api/live", tags=["Live Classes"])


@app.get("/")
async def root():
    return {"message": "E-Learning Platform API", "version": "1.0.0"}


@app.get("/health")
async def health_check():
    return {"status": "healthy"}

