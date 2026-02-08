from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session
from typing import List, Optional
from app.core.database import get_db
from app.models.user import User
from app.api.dependencies import get_current_user
from app.services.rag_service import RAGService
from app.middleware.rate_limiter import general_limiter
from app.core.exceptions import handle_business_exception
from app.schemas.rag import (
    QuestionRequest,
    QuestionResponse,
    QueryHistoryResponse,
    ContentIndexingResponse
)
from pydantic import BaseModel

router = APIRouter()


@router.post("/ask", response_model=QuestionResponse)
async def ask_question(
    request: QuestionRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Ask a question about course materials using AI."""
    try:
        rag_service = RAGService(db)
        result = await rag_service.answer_student_question(
            student_id=current_user.id,
            course_id=request.course_id,
            question=request.question
        )
        
        return QuestionResponse(
            answer=result["answer"],
            confidence=result["confidence"],
            sources=result["sources"],
            response_time_ms=result["response_time_ms"]
        )
        
    except Exception as e:
        raise handle_business_exception(e)


@router.get("/history", response_model=List[QueryHistoryResponse])
async def get_query_history(
    course_id: Optional[int] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get student's question history."""
    try:
        rag_service = RAGService(db)
        history = rag_service.get_student_query_history(
            student_id=current_user.id,
            course_id=course_id
        )
        
        return [QueryHistoryResponse(**item) for item in history]
        
    except Exception as e:
        raise handle_business_exception(e)


@router.post("/index-content/{content_id}", response_model=ContentIndexingResponse)
async def index_content(
    content_id: int,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Process and index content for RAG (teachers only)."""
    try:
        # Only teachers can trigger indexing
        if current_user.role != "teacher":
            raise HTTPException(status_code=403, detail="Only teachers can index content")
        
        # Check if user owns the content
        from app.models.course import CourseContent, Course
        content = db.query(CourseContent).join(Course).filter(
            CourseContent.id == content_id,
            Course.teacher_id == current_user.id
        ).first()
        
        if not content:
            raise HTTPException(status_code=404, detail="Content not found or access denied")
        
        # Process in background
        rag_service = RAGService(db)
        result = await rag_service.process_uploaded_content(content_id)
        
        return ContentIndexingResponse(
            content_id=content_id,
            status=result["status"],
            chunks_created=result["chunks_created"]
        )
        
    except Exception as e:
        raise handle_business_exception(e)


@router.get("/index-status/{content_id}")
async def get_index_status(
    content_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get indexing status for content."""
    try:
        from app.models.rag import VectorIndex
        from app.models.course import CourseContent, Course
        
        # Check access
        content = db.query(CourseContent).join(Course).filter(
            CourseContent.id == content_id
        ).first()
        
        if not content:
            raise HTTPException(status_code=404, detail="Content not found")
        
        # Only teachers or enrolled students can check status
        if current_user.role == "student":
            # Check if enrolled
            from app.models.course import Enrollment, EnrollmentStatus
            enrollment = db.query(Enrollment).filter(
                Enrollment.course_id == content.course_id,
                Enrollment.student_id == current_user.id,
                Enrollment.status == EnrollmentStatus.APPROVED
            ).first()
            
            if not enrollment:
                raise HTTPException(status_code=403, detail="Access denied")
        
        # Get index status
        vector_index = db.query(VectorIndex).filter(
            VectorIndex.content_id == content_id
        ).first()
        
        if not vector_index:
            return {"content_id": content_id, "status": "not_indexed", "chunks_created": 0}
        
        status_map = {0: "not_indexed", 1: "indexing", 2: "completed"}
        
        return {
            "content_id": content_id,
            "status": status_map.get(vector_index.is_indexed, "unknown"),
            "chunks_created": vector_index.chunk_count,
            "last_updated": vector_index.last_updated.isoformat() if vector_index.last_updated else None,
            "error_message": vector_index.error_message
        }
        
    except Exception as e:
        raise handle_business_exception(e)
