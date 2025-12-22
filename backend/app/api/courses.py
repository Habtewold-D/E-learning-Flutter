from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from typing import List
from app.core.database import get_db
from app.models.user import User, UserRole
from app.models.course import Course, CourseContent, ContentType
from app.schemas.course import CourseCreate, CourseResponse, ContentCreate, ContentResponse, CourseWithContent
from app.api.dependencies import get_current_user
from app.services.file_service import save_uploaded_file
import os
from app.core.config import settings

router = APIRouter()


@router.post("/", response_model=CourseResponse)
async def create_course(
    course_data: CourseCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create a new course (teachers only)."""
    if current_user.role != UserRole.TEACHER:
        raise HTTPException(status_code=403, detail="Only teachers can create courses")
    
    new_course = Course(
        title=course_data.title,
        description=course_data.description,
        teacher_id=current_user.id
    )
    db.add(new_course)
    db.commit()
    db.refresh(new_course)
    return CourseResponse.model_validate(new_course)


@router.get("/", response_model=List[CourseResponse])
async def list_courses(db: Session = Depends(get_db)):
    """List all courses."""
    courses = db.query(Course).all()
    return [CourseResponse.model_validate(course) for course in courses]


@router.get("/{course_id}", response_model=CourseWithContent)
async def get_course(course_id: int, db: Session = Depends(get_db)):
    """Get course details with content."""
    course = db.query(Course).filter(Course.id == course_id).first()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    
    return CourseWithContent(
        id=course.id,
        title=course.title,
        description=course.description,
        teacher_id=course.teacher_id,
        contents=[ContentResponse.model_validate(content) for content in course.contents]
    )


@router.post("/{course_id}/content", response_model=ContentResponse)
async def upload_content(
    course_id: int,
    title: str = Form(...),
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Upload course content (video or PDF)."""
    course = db.query(Course).filter(Course.id == course_id).first()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    
    if course.teacher_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only course teacher can upload content")
    
    # Auto-detect file type from extension
    if not file.filename:
        raise HTTPException(status_code=400, detail="File must have a filename")
    
    file_extension = file.filename.lower().split('.')[-1] if '.' in file.filename else ''
    
    if file_extension == 'pdf':
        content_type = ContentType.PDF
    elif file_extension in ['mp4', 'mov', 'avi', 'mkv', 'webm']:
        content_type = ContentType.VIDEO
    else:
        raise HTTPException(
            status_code=400, 
            detail=f"Unsupported file type. Supported: PDF (.pdf) or Video (.mp4, .mov, .avi, .mkv, .webm)"
        )
    
    # Save file
    file_url = await save_uploaded_file(file, course_id, content_type)
    
    # Create content record
    new_content = CourseContent(
        course_id=course_id,
        type=content_type,
        title=title,
        url=file_url
    )
    db.add(new_content)
    db.commit()
    db.refresh(new_content)
    
    return ContentResponse.model_validate(new_content)

