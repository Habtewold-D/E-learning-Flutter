from sqlalchemy import Column, Integer, String, ForeignKey, Enum, DateTime, UniqueConstraint
from sqlalchemy.orm import relationship
import enum
from sqlalchemy.sql import func
from app.core.database import Base


class ContentType(str, enum.Enum):
    VIDEO = "video"
    PDF = "pdf"


class EnrollmentStatus(str, enum.Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"


class Course(Base):
    __tablename__ = "courses"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    description = Column(String)
    teacher_id = Column(Integer, ForeignKey("users.id"), nullable=False)

    # Relationships
    teacher = relationship("User", back_populates="courses")
    contents = relationship("CourseContent", back_populates="course", cascade="all, delete-orphan")
    exams = relationship("Exam", back_populates="course", cascade="all, delete-orphan")
    live_classes = relationship("LiveClass", back_populates="course", cascade="all, delete-orphan")
    enrollments = relationship("Enrollment", back_populates="course", cascade="all, delete-orphan")


class CourseContent(Base):
    __tablename__ = "course_contents"

    id = Column(Integer, primary_key=True, index=True)
    course_id = Column(Integer, ForeignKey("courses.id"), nullable=False)
    type = Column(Enum(ContentType), nullable=False)
    title = Column(String, nullable=False)
    url = Column(String, nullable=False)  # File path or external URL

    # Relationships
    course = relationship("Course", back_populates="contents")
    progress_entries = relationship("ContentProgress", back_populates="content", cascade="all, delete-orphan")


class Enrollment(Base):
    __tablename__ = "enrollments"
    __table_args__ = (
        UniqueConstraint("course_id", "student_id", name="uq_enrollment_course_student"),
    )

    id = Column(Integer, primary_key=True, index=True)
    course_id = Column(Integer, ForeignKey("courses.id"), nullable=False)
    student_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    status = Column(Enum(EnrollmentStatus), nullable=False, default=EnrollmentStatus.PENDING)
    enrolled_at = Column(DateTime, server_default=func.now(), nullable=False)

    course = relationship("Course", back_populates="enrollments")
    student = relationship("User", back_populates="enrollments")


class ContentProgress(Base):
    __tablename__ = "content_progress"
    __table_args__ = (
        UniqueConstraint("content_id", "student_id", name="uq_content_progress"),
    )

    id = Column(Integer, primary_key=True, index=True)
    content_id = Column(Integer, ForeignKey("course_contents.id"), nullable=False)
    student_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    completed_at = Column(DateTime, server_default=func.now(), nullable=False)

    content = relationship("CourseContent", back_populates="progress_entries")
    student = relationship("User", back_populates="content_progress")

