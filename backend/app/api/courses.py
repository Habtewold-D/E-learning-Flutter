from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List
from app.core.database import get_db
from app.models.user import User, UserRole
from app.models.course import Course, CourseContent, ContentType, Enrollment, ContentProgress, EnrollmentStatus
from app.schemas.course import (
    CourseCreate,
    CourseResponse,
    ContentCreate,
    ContentResponse,
    CourseWithContent,
    CourseBrowseResponse,
    EnrolledCourseResponse,
    CourseProgressResponse,
    EnrollmentResponse,
    EnrollmentRequestResponse,
    CourseUpdate,
    StudentSummary,
)
from app.api.dependencies import get_current_user
from app.services.file_service import save_uploaded_file
import os
from app.core.config import settings
from app.services.notification_service import notify_users

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
@router.get("/browse", response_model=List[CourseBrowseResponse])
async def browse_courses(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """List courses with enrollment info for students."""
    courses = db.query(Course).all()
    enrollments = db.query(Enrollment).filter(Enrollment.student_id == current_user.id).all()
    enrollment_by_course = {e.course_id: e for e in enrollments}

    responses: List[CourseBrowseResponse] = []
    for course in courses:
        enrollment = enrollment_by_course.get(course.id)
        enrollment_status = enrollment.status if enrollment else None
        responses.append(
            CourseBrowseResponse(
                id=course.id,
                title=course.title,
                description=course.description,
                teacher_id=course.teacher_id,
                teacher_name=course.teacher.name if course.teacher else "",
                students_count=len([e for e in course.enrollments if e.status == EnrollmentStatus.APPROVED]),
                content_count=len(course.contents),
                is_enrolled=enrollment_status == EnrollmentStatus.APPROVED,
                enrollment_status=enrollment_status,
            )
        )
    return responses


@router.get("/teacher/me", response_model=List[CourseResponse])
async def list_my_courses(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """List courses for the current teacher."""
    if current_user.role != UserRole.TEACHER:
        raise HTTPException(status_code=403, detail="Only teachers can access this endpoint")
    courses = db.query(Course).filter(Course.teacher_id == current_user.id).all()
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


@router.get("/{course_id}/students", response_model=List[StudentSummary])
async def list_course_students(
    course_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """List enrolled students for a course (teacher only)."""
    if current_user.role != UserRole.TEACHER:
        raise HTTPException(status_code=403, detail="Only teachers can access this endpoint")

    course = db.query(Course).filter(Course.id == course_id).first()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    if course.teacher_id != current_user.id:
        raise HTTPException(status_code=403, detail="You can only view your own course")

    enrollments = db.query(Enrollment).filter(
        Enrollment.course_id == course_id,
        Enrollment.status == EnrollmentStatus.APPROVED,
    ).all()
    return [
        StudentSummary(
            id=e.student.id,
            name=e.student.name,
            email=e.student.email,
        )
        for e in enrollments
        if e.student is not None
    ]


@router.patch("/{course_id}", response_model=CourseResponse)
async def update_course(
    course_id: int,
    course_data: CourseUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update course title/description (teacher only)."""
    if current_user.role != UserRole.TEACHER:
        raise HTTPException(status_code=403, detail="Only teachers can update courses")

    course = db.query(Course).filter(Course.id == course_id).first()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    if course.teacher_id != current_user.id:
        raise HTTPException(status_code=403, detail="You can only edit your own courses")

    update_data = course_data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(course, key, value)

    db.commit()
    db.refresh(course)
    return CourseResponse.model_validate(course)


@router.delete("/{course_id}")
async def delete_course(
    course_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete a course (teacher only)."""
    if current_user.role != UserRole.TEACHER:
        raise HTTPException(status_code=403, detail="Only teachers can delete courses")

    course = db.query(Course).filter(Course.id == course_id).first()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    if course.teacher_id != current_user.id:
        raise HTTPException(status_code=403, detail="You can only delete your own courses")

    db.delete(course)
    db.commit()
    return {"detail": "Course deleted"}


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

    try:
        approved_students = (
            db.query(Enrollment)
            .filter(Enrollment.course_id == course_id)
            .filter(Enrollment.status == EnrollmentStatus.APPROVED)
            .all()
        )
        student_ids = [e.student_id for e in approved_students]
        notify_users(
            db=db,
            user_ids=student_ids,
            title="New course content",
            body=f"New content added in {course.title}: {title}",
            data={
                "type": "course_content",
                "course_id": str(course_id),
                "content_id": str(new_content.id),
            },
        )
    except Exception:
        pass
    
    return ContentResponse.model_validate(new_content)


@router.post("/{course_id}/enroll", response_model=EnrollmentResponse)
async def enroll_in_course(
    course_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Request enrollment in a course (pending approval)."""
    if current_user.role != UserRole.STUDENT:
        raise HTTPException(status_code=403, detail="Only students can enroll")
    course = db.query(Course).filter(Course.id == course_id).first()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")

    existing = db.query(Enrollment).filter(
        Enrollment.course_id == course_id,
        Enrollment.student_id == current_user.id
    ).first()
    if existing:
        if existing.status == EnrollmentStatus.REJECTED:
            existing.status = EnrollmentStatus.PENDING
            db.commit()
            db.refresh(existing)
            try:
                notify_users(
                    db=db,
                    user_ids=[course.teacher_id],
                    title="New enrollment request",
                    body=f"{current_user.name} requested to join {course.title}",
                    data={
                        "type": "enrollment_request",
                        "course_id": str(course_id),
                        "student_id": str(current_user.id),
                    },
                )
            except Exception:
                pass
        return EnrollmentResponse(
            course_id=course_id,
            student_id=current_user.id,
            enrolled_at=str(existing.enrolled_at),
            status=existing.status,
        )

    enrollment = Enrollment(
        course_id=course_id,
        student_id=current_user.id,
        status=EnrollmentStatus.PENDING,
    )
    db.add(enrollment)
    db.commit()
    db.refresh(enrollment)
    try:
        notify_users(
            db=db,
            user_ids=[course.teacher_id],
            title="New enrollment request",
            body=f"{current_user.name} requested to join {course.title}",
            data={
                "type": "enrollment_request",
                "course_id": str(course_id),
                "student_id": str(current_user.id),
            },
        )
    except Exception:
        pass
    return EnrollmentResponse(
        course_id=course_id,
        student_id=current_user.id,
        enrolled_at=str(enrollment.enrolled_at),
        status=enrollment.status,
    )


@router.delete("/{course_id}/enroll")
async def unenroll_from_course(
    course_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Unenroll current student from a course."""
    enrollment = db.query(Enrollment).filter(
        Enrollment.course_id == course_id,
        Enrollment.student_id == current_user.id
    ).first()
    if not enrollment:
        raise HTTPException(status_code=404, detail="Enrollment not found")

    # Remove progress entries for this course
    content_ids = [c.id for c in db.query(CourseContent).filter(CourseContent.course_id == course_id).all()]
    if content_ids:
        db.query(ContentProgress).filter(
            ContentProgress.student_id == current_user.id,
            ContentProgress.content_id.in_(content_ids)
        ).delete(synchronize_session=False)

    db.delete(enrollment)
    db.commit()
    return {"message": "Unenrolled successfully"}


@router.get("/enrolled/me", response_model=List[EnrolledCourseResponse])
async def list_enrolled_courses(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """List courses the current student is enrolled in with progress."""
    if current_user.role != UserRole.STUDENT:
        raise HTTPException(status_code=403, detail="Only students can access this endpoint")

    enrollments = db.query(Enrollment).filter(
        Enrollment.student_id == current_user.id,
        Enrollment.status == EnrollmentStatus.APPROVED,
    ).all()
    course_ids = [e.course_id for e in enrollments]
    courses = db.query(Course).filter(Course.id.in_(course_ids)).all() if course_ids else []

    responses: List[EnrolledCourseResponse] = []
    for course in courses:
        content_ids = [c.id for c in course.contents]
        content_count = len(content_ids)
        completed_count = 0
        if content_ids:
            completed_count = db.query(ContentProgress).filter(
                ContentProgress.student_id == current_user.id,
                ContentProgress.content_id.in_(content_ids)
            ).count()
        progress = (completed_count / content_count) * 100 if content_count > 0 else 0

        responses.append(
            EnrolledCourseResponse(
                id=course.id,
                title=course.title,
                description=course.description,
                content_count=content_count,
                completed_content=completed_count,
                progress=progress,
            )
        )
    return responses


@router.get("/requests/pending", response_model=List[EnrollmentRequestResponse])
async def list_pending_requests(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """List pending enrollment requests for the current teacher."""
    if current_user.role != UserRole.TEACHER:
        raise HTTPException(status_code=403, detail="Only teachers can access requests")

    pending = (
        db.query(Enrollment)
        .join(Course, Enrollment.course_id == Course.id)
        .filter(
            Course.teacher_id == current_user.id,
            Enrollment.status == EnrollmentStatus.PENDING,
        )
        .all()
    )

    responses: List[EnrollmentRequestResponse] = []
    for enrollment in pending:
        responses.append(
            EnrollmentRequestResponse(
                id=enrollment.id,
                course_id=enrollment.course_id,
                course_title=enrollment.course.title,
                student_id=enrollment.student_id,
                student_name=enrollment.student.name,
                student_email=enrollment.student.email,
                status=enrollment.status,
                requested_at=str(enrollment.enrolled_at),
            )
        )
    return responses


@router.post("/requests/{request_id}/approve", response_model=EnrollmentRequestResponse)
async def approve_enrollment_request(
    request_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Approve a pending enrollment request (teacher only)."""
    if current_user.role != UserRole.TEACHER:
        raise HTTPException(status_code=403, detail="Only teachers can approve requests")

    enrollment = (
        db.query(Enrollment)
        .join(Course, Enrollment.course_id == Course.id)
        .filter(Enrollment.id == request_id, Course.teacher_id == current_user.id)
        .first()
    )
    if not enrollment:
        raise HTTPException(status_code=404, detail="Request not found")

    enrollment.status = EnrollmentStatus.APPROVED
    db.commit()
    db.refresh(enrollment)
    try:
        notify_users(
            db=db,
            user_ids=[enrollment.student_id],
            title="Enrollment approved",
            body=f"You have been approved to join {enrollment.course.title}",
            data={
                "type": "enrollment_approved",
                "course_id": str(enrollment.course_id),
            },
        )
    except Exception:
        pass
    return EnrollmentRequestResponse(
        id=enrollment.id,
        course_id=enrollment.course_id,
        course_title=enrollment.course.title,
        student_id=enrollment.student_id,
        student_name=enrollment.student.name,
        student_email=enrollment.student.email,
        status=enrollment.status,
        requested_at=str(enrollment.enrolled_at),
    )


@router.post("/requests/{request_id}/reject", response_model=EnrollmentRequestResponse)
async def reject_enrollment_request(
    request_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Reject a pending enrollment request (teacher only)."""
    if current_user.role != UserRole.TEACHER:
        raise HTTPException(status_code=403, detail="Only teachers can reject requests")

    enrollment = (
        db.query(Enrollment)
        .join(Course, Enrollment.course_id == Course.id)
        .filter(Enrollment.id == request_id, Course.teacher_id == current_user.id)
        .first()
    )
    if not enrollment:
        raise HTTPException(status_code=404, detail="Request not found")

    enrollment.status = EnrollmentStatus.REJECTED
    db.commit()
    db.refresh(enrollment)
    try:
        notify_users(
            db=db,
            user_ids=[enrollment.student_id],
            title="Enrollment rejected",
            body=f"Your enrollment request for {enrollment.course.title} was rejected",
            data={
                "type": "enrollment_rejected",
                "course_id": str(enrollment.course_id),
            },
        )
    except Exception:
        pass
    return EnrollmentRequestResponse(
        id=enrollment.id,
        course_id=enrollment.course_id,
        course_title=enrollment.course.title,
        student_id=enrollment.student_id,
        student_name=enrollment.student.name,
        student_email=enrollment.student.email,
        status=enrollment.status,
        requested_at=str(enrollment.enrolled_at),
    )


@router.post("/{course_id}/content/{content_id}/complete")
async def mark_content_complete(
    course_id: int,
    content_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Mark a content item as completed for the current student."""
    if current_user.role != UserRole.STUDENT:
        raise HTTPException(status_code=403, detail="Only students can mark content complete")

    content = db.query(CourseContent).filter(
        CourseContent.id == content_id,
        CourseContent.course_id == course_id
    ).first()
    if not content:
        raise HTTPException(status_code=404, detail="Content not found")

    existing = db.query(ContentProgress).filter(
        ContentProgress.content_id == content_id,
        ContentProgress.student_id == current_user.id
    ).first()
    if existing:
        return {"message": "Already completed"}

    db.add(ContentProgress(content_id=content_id, student_id=current_user.id))
    db.commit()
    return {"message": "Marked complete"}


@router.delete("/{course_id}/content/{content_id}")
async def delete_course_content(
    course_id: int,
    content_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete a course content item (teacher only)."""
    if current_user.role != UserRole.TEACHER:
        raise HTTPException(status_code=403, detail="Only teachers can delete content")

    course = db.query(Course).filter(Course.id == course_id).first()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    if course.teacher_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only course teacher can delete content")

    content = db.query(CourseContent).filter(
        CourseContent.id == content_id,
        CourseContent.course_id == course_id
    ).first()
    if not content:
        raise HTTPException(status_code=404, detail="Content not found")

    db.delete(content)
    db.commit()
    return {"detail": "Content deleted"}


@router.post("/{course_id}/progress/{content_id}/complete")
async def mark_content_complete_legacy(
    course_id: int,
    content_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Legacy route used by older clients (maps to content completion)."""
    return await mark_content_complete(course_id, content_id, current_user, db)


@router.get("/{course_id}/progress", response_model=CourseProgressResponse)
async def get_course_progress(
    course_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get progress for current student in a course."""
    content_ids = [c.id for c in db.query(CourseContent).filter(CourseContent.course_id == course_id).all()]
    content_count = len(content_ids)
    completed_ids: List[int] = []
    if content_ids:
        completed_ids = [
            c.content_id
            for c in db.query(ContentProgress).filter(
                ContentProgress.student_id == current_user.id,
                ContentProgress.content_id.in_(content_ids)
            ).all()
        ]
    completed_count = len(completed_ids)
    progress = (completed_count / content_count) * 100 if content_count > 0 else 0

    return CourseProgressResponse(
        course_id=course_id,
        content_count=content_count,
        completed_count=completed_count,
        progress=progress,
        completed_content_ids=completed_ids,
    )

