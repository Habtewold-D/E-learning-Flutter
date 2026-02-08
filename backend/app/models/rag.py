from sqlalchemy import Column, Integer, String, ForeignKey, Text, DateTime, Float, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base


class DocumentChunk(Base):
    """Represents a chunk of processed document content for RAG."""
    
    __tablename__ = "document_chunks"

    id = Column(Integer, primary_key=True, index=True)
    content_id = Column(Integer, ForeignKey("course_contents.id"), nullable=False)
    chunk_text = Column(Text, nullable=False)
    chunk_index = Column(Integer, nullable=False)  # Order in document
    chunk_metadata = Column(JSON, nullable=True)  # Page numbers, timestamps, etc.
    embedding = Column(JSON, nullable=False)  # Vector embedding
    created_at = Column(DateTime, server_default=func.now(), nullable=False)

    # Relationships
    content = relationship("CourseContent", back_populates="chunks")


class StudentQuery(Base):
    """Stores student questions and AI responses."""
    
    __tablename__ = "student_queries"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    course_id = Column(Integer, ForeignKey("courses.id"), nullable=False)
    question = Column(Text, nullable=False)
    answer = Column(Text, nullable=True)
    context_chunks = Column(JSON, nullable=True)  # Retrieved chunks used
    confidence_score = Column(Float, nullable=True)
    response_time_ms = Column(Integer, nullable=True)
    created_at = Column(DateTime, server_default=func.now(), nullable=False)

    # Relationships
    student = relationship("User")
    course = relationship("Course")


class VectorIndex(Base):
    """Manages vector index status and metadata."""
    
    __tablename__ = "vector_indices"

    id = Column(Integer, primary_key=True, index=True)
    content_id = Column(Integer, ForeignKey("course_contents.id"), nullable=False, unique=True)
    is_indexed = Column(Integer, default=0, nullable=False)  # 0=not indexed, 1=indexing, 2=completed
    chunk_count = Column(Integer, default=0, nullable=False)
    last_updated = Column(DateTime, server_default=func.now(), nullable=False)
    error_message = Column(Text, nullable=True)

    # Relationships
    content = relationship("CourseContent", back_populates="vector_index")
