"""
Initialize the database with tables.
Run this script to create all database tables.
"""
from app.core.database import engine, Base
from app.models import User, Course, CourseContent, Enrollment, ContentProgress, Exam, Question, Result, NotificationToken, InAppNotification, DocumentChunk, StudentQuery, VectorIndex

if __name__ == "__main__":
    print("Creating database tables...")
    Base.metadata.create_all(bind=engine)
    print("Database tables created successfully!")

