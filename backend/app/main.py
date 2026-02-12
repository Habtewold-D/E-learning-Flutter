from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi_utils.tasks import repeat_every
from sqlalchemy.orm import Session
from app.core.database import SessionLocal
from app.services.live_class_service import _auto_update_statuses
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.api import auth, courses, exams, live, live_class, admin, notifications, rag
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware
from app.middleware.rate_limiter import general_limiter, rate_limit_exceeded_handler
from pathlib import Path

app = FastAPI(
    title="E-Learning Platform API",
    description="Backend API for e-learning platform",
    version="1.0.0"
)

app.state.limiter = general_limiter
app.add_exception_handler(RateLimitExceeded, rate_limit_exceeded_handler)
app.add_middleware(SlowAPIMiddleware)

# Serve uploaded files
Path(settings.UPLOAD_DIR).mkdir(parents=True, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=settings.UPLOAD_DIR), name="uploads")

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])
app.include_router(courses.router, prefix="/api/courses", tags=["Courses"])
app.include_router(exams.router, prefix="/api/exams", tags=["Exams"])
app.include_router(live.router, prefix="/api/live", tags=["Live Classes"])
app.include_router(live_class.router, prefix="/api", tags=["Live Class Scheduling"])
app.include_router(admin.router, prefix="/api/admin", tags=["Admin"])
app.include_router(notifications.router, prefix="/api/notifications", tags=["Notifications"])
app.include_router(rag.router, prefix="/api/rag", tags=["RAG - AI Assistant"])


@app.on_event("startup")
@repeat_every(seconds=60, wait_first=True)
def refresh_live_class_statuses() -> None:
    """Background task to promote scheduled→active and active→ended based on time."""
    db: Session = SessionLocal()
    try:
        _auto_update_statuses(db)
    finally:
        db.close()


@app.get("/")
async def root():
    return {"message": "E-Learning Platform API", "version": "1.0.0"}


@app.get("/health")
async def health_check():
    return {"status": "healthy"}

