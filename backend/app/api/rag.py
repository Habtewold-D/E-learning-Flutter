from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from pydantic import BaseModel
from app.core.database import get_db
from app.models.user import User
from app.api.dependencies import get_current_user
from app.services.rag_service import RAGService
from app.services.file_service import save_uploaded_file
from app.models.course import ContentType

router = APIRouter()
rag_service = RAGService()


class QuestionRequest(BaseModel):
    question: str
    course_content_id: int


class RAGQuestionResponse(BaseModel):
    answer: str
    sources: list[str] = []


@router.post("/process/{course_content_id}")
async def process_existing_pdf_for_rag(
    course_content_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Process an existing PDF course content for RAG (manual reprocessing)."""
    from app.models.course import CourseContent
    
    # Get the course content
    content = db.query(CourseContent).filter(CourseContent.id == course_content_id).first()
    if not content:
        raise HTTPException(status_code=404, detail="Course content not found")
    
    if content.type != ContentType.PDF:
        raise HTTPException(status_code=400, detail="Content must be a PDF")
    
    # Process PDF for RAG using the existing file
    try:
        await rag_service.process_pdf(content.url, course_content_id)
        return {
            "message": "PDF processed successfully for RAG",
            "content_id": course_content_id
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing PDF: {str(e)}")


@router.post("/ask", response_model=RAGQuestionResponse)
async def ask_question(
    question_data: QuestionRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Ask a question about a PDF using RAG."""
    try:
        answer, sources = await rag_service.ask_question(
            question_data.question,
            question_data.course_content_id
        )
        return RAGQuestionResponse(answer=answer, sources=sources)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error answering question: {str(e)}")

