from sqlalchemy import Column, Integer, String, ForeignKey, Enum
from sqlalchemy.orm import relationship
import enum
from app.core.database import Base


class ContentType(str, enum.Enum):
    VIDEO = "video"
    PDF = "pdf"


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


class CourseContent(Base):
    __tablename__ = "course_contents"

    id = Column(Integer, primary_key=True, index=True)
    course_id = Column(Integer, ForeignKey("courses.id"), nullable=False)
    type = Column(Enum(ContentType), nullable=False)
    title = Column(String, nullable=False)
    url = Column(String, nullable=False)  # File path or external URL

    # Relationships
    course = relationship("Course", back_populates="contents")

