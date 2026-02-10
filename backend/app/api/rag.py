from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks, Request
import asyncio
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, timedelta
from app.core.database import get_db, SessionLocal
from app.models.user import User
from app.api.dependencies import get_current_user
from app.services.rag_service import RAGService
from app.middleware.rate_limiter import general_limiter
from app.core.exceptions import handle_business_exception
from app.schemas.rag import (
    QuestionRequest,
    QuestionResponse,
    QueryHistoryResponse,
    ContentIndexingResponse,
    ThreadSummaryResponse,
    ThreadMessageResponse,
)
from pydantic import BaseModel
import chromadb
from chromadb.config import Settings as ChromaSettings

router = APIRouter()


def _run_indexing_task(content_id: int) -> None:
    db = SessionLocal()
    try:
        rag_service = RAGService(db)
        asyncio.run(rag_service.process_uploaded_content(content_id))
    finally:
        db.close()


@router.post("/ask", response_model=QuestionResponse)
@general_limiter.limit("10/minute")
async def ask_question(
    payload: QuestionRequest,
    request: Request,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Ask a question about course materials using AI."""
    try:
        rag_service = RAGService(db)
        result = await rag_service.answer_student_question(
            student_id=current_user.id,
            course_id=payload.course_id,
            question=payload.question,
            thread_id=payload.thread_id,
            thread_title=payload.thread_title,
        )
        
        return QuestionResponse(
            answer=result["answer"],
            confidence=result["confidence"],
            sources=result["sources"],
            response_time_ms=result["response_time_ms"],
            thread_id=result.get("thread_id"),
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


@router.get("/threads", response_model=List[ThreadSummaryResponse])
async def list_threads(
    course_id: Optional[int] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """List conversation threads for a student."""
    try:
        rag_service = RAGService(db)
        threads = rag_service.list_threads(student_id=current_user.id, course_id=course_id)
        return [ThreadSummaryResponse(**item) for item in threads]
    except Exception as e:
        raise handle_business_exception(e)


@router.get("/threads/{thread_id}", response_model=List[ThreadMessageResponse])
async def get_thread_messages(
    thread_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get messages for a thread."""
    try:
        rag_service = RAGService(db)
        messages = rag_service.get_thread_messages(student_id=current_user.id, thread_id=thread_id)
        return [ThreadMessageResponse(**item) for item in messages]
    except Exception as e:
        raise handle_business_exception(e)


@router.post("/index-content/{content_id}", response_model=ContentIndexingResponse)
async def index_content(
    content_id: int,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Process and index content for RAG (teachers/admins only)."""
    try:
        # Only teachers or admins can trigger indexing
        role_value = current_user.role.value if hasattr(current_user.role, "value") else str(current_user.role)
        role_value = role_value.lower()
        if role_value not in {"teacher", "admin"}:
            raise HTTPException(status_code=403, detail="Only teachers or admins can index content")
        
        # Check if user owns the content
        from app.models.course import CourseContent, Course
        content_query = db.query(CourseContent).join(Course).filter(
            CourseContent.id == content_id
        )
        if role_value == "teacher":
            content_query = content_query.filter(Course.teacher_id == current_user.id)
        content = content_query.first()
        
        if not content:
            raise HTTPException(status_code=404, detail="Content not found or access denied")
        
        # Process in background with a fresh DB session
        background_tasks.add_task(_run_indexing_task, content_id)
        
        return ContentIndexingResponse(
            content_id=content_id,
            status="indexing",
            chunks_created=0
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

        # If stuck in indexing, verify in ChromaDB and auto-fix status
        if vector_index.is_indexed == 1:
            try:
                chroma_client = chromadb.PersistentClient(
                    path="./chroma_db",
                    settings=ChromaSettings(anonymized_telemetry=False),
                )
                collection = chroma_client.get_or_create_collection("course_content")
                results = collection.get(where={"content_id": {"$eq": str(content_id)}})
                ids = results.get("ids", []) if isinstance(results, dict) else []

                if ids:
                    vector_index.is_indexed = 2
                    vector_index.chunk_count = len(ids)
                    vector_index.last_updated = func.now()
                    vector_index.error_message = None
                    db.commit()
                else:
                    # If indexing has been stuck too long, mark as failed
                    if vector_index.last_updated and vector_index.last_updated < datetime.utcnow() - timedelta(minutes=20):
                        vector_index.is_indexed = 0
                        vector_index.error_message = "Indexing timed out. Please retry."
                        vector_index.last_updated = func.now()
                        db.commit()
            except Exception:
                # Keep current status if Chroma check fails
                pass
        
        return {
            "content_id": content_id,
            "status": status_map.get(vector_index.is_indexed, "unknown"),
            "chunks_created": vector_index.chunk_count,
            "last_updated": vector_index.last_updated.isoformat() if vector_index.last_updated else None,
            "error_message": vector_index.error_message
        }
        
    except Exception as e:
        raise handle_business_exception(e)
