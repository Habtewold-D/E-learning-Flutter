from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime


class QuestionRequest(BaseModel):
    """Request model for asking a question."""
    course_id: int = Field(..., description="ID of the course")
    question: str = Field(..., min_length=2, max_length=1000, description="Student's question")
    thread_id: Optional[str] = Field(default=None, description="Existing thread id")
    thread_title: Optional[str] = Field(default=None, description="Optional thread title for new thread")


class QuestionResponse(BaseModel):
    """Response model for AI-generated answer."""
    answer: str = Field(..., description="AI-generated answer")
    confidence: float = Field(..., ge=0.0, le=1.0, description="Confidence score")
    sources: List[Dict[str, Any]] = Field(default_factory=list, description="Source materials used")
    response_time_ms: int = Field(..., description="Response time in milliseconds")
    thread_id: Optional[str] = Field(default=None, description="Thread id")


class QueryHistoryResponse(BaseModel):
    """Response model for query history."""
    id: int
    question: str
    answer: str
    confidence: float
    response_time_ms: int
    created_at: str
    sources: List[Dict[str, Any]]


class ThreadSummaryResponse(BaseModel):
    """Thread list response."""
    thread_id: str
    course_id: int
    title: str
    last_question: str
    last_answer: str
    updated_at: str


class ThreadMessageResponse(BaseModel):
    """Messages for a thread."""
    question: str
    answer: str
    confidence: float
    sources: List[Dict[str, Any]]
    created_at: str


class ContentIndexingResponse(BaseModel):
    """Response model for content indexing."""
    content_id: int
    status: str
    chunks_created: int


class IndexStatusResponse(BaseModel):
    """Response model for index status."""
    content_id: int
    status: str
    chunks_created: int
    last_updated: Optional[str] = None
    error_message: Optional[str] = None
