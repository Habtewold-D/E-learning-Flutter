from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.core.database import get_db
from app.models.user import User, UserRole
from app.models.course import Course, Enrollment, EnrollmentStatus
from app.models.exam import Exam, Question, Result
from app.schemas.exam import ExamCreate, ExamResponse, ExamSubmit, ResultResponse, QuestionResponse, ResultWithStudentResponse, QuestionCreate, QuestionUpdate, ExamUpdate, StudentExamListResponse
from app.api.dependencies import get_current_user
from app.services.notification_service import notify_users

router = APIRouter()


@router.post("/", response_model=ExamResponse)
async def create_exam(
    exam_data: ExamCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create an exam with questions (teachers only)."""
    if current_user.role != UserRole.TEACHER:
        raise HTTPException(status_code=403, detail="Only teachers can create exams")
    
    # Verify course exists and belongs to teacher
    course = db.query(Course).filter(Course.id == exam_data.course_id).first()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    if course.teacher_id != current_user.id:
        raise HTTPException(status_code=403, detail="You can only create exams for your own courses")
    
    # Create exam
    new_exam = Exam(
        course_id=exam_data.course_id,
        title=exam_data.title,
        description=exam_data.description
    )
    db.add(new_exam)
    db.flush()
    
    # Create questions
    for q_data in exam_data.questions:
        question = Question(
            exam_id=new_exam.id,
            question=q_data.question,
            option_a=q_data.option_a,
            option_b=q_data.option_b,
            option_c=q_data.option_c,
            option_d=q_data.option_d,
            correct_option=q_data.correct_option.lower()
        )
        db.add(question)
    
    db.commit()
    db.refresh(new_exam)

    try:
        approved_students = (
            db.query(Enrollment)
            .filter(Enrollment.course_id == new_exam.course_id)
            .filter(Enrollment.status == EnrollmentStatus.APPROVED)
            .all()
        )
        student_ids = [e.student_id for e in approved_students]
        notify_users(
            db=db,
            user_ids=student_ids,
            title="New exam available",
            body=f"{course.title}: {new_exam.title}",
            data={
                "type": "exam_created",
                "course_id": str(new_exam.course_id),
                "exam_id": str(new_exam.id),
            },
        )
    except Exception:
        pass
    
    return ExamResponse(
        id=new_exam.id,
        course_id=new_exam.course_id,
        title=new_exam.title,
        description=new_exam.description,
        questions=[QuestionResponse.model_validate(q) for q in new_exam.questions]
    )


@router.get("/course/{course_id}", response_model=List[ExamResponse])
async def list_exams(course_id: int, db: Session = Depends(get_db)):
    """List all exams for a course."""
    exams = db.query(Exam).filter(Exam.course_id == course_id).all()
    return [
        ExamResponse(
            id=exam.id,
            course_id=exam.course_id,
            title=exam.title,
            description=exam.description,
            questions=[QuestionResponse.model_validate(q) for q in exam.questions]
        )
        for exam in exams
    ]


@router.get("/my", response_model=List[StudentExamListResponse])
async def list_my_exams(
    course_id: int | None = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """List exams for the current student (optionally filtered by course)."""
    if current_user.role != UserRole.STUDENT:
        raise HTTPException(status_code=403, detail="Only students can access this endpoint")

    enrolled_course_ids = [
        e.course_id
        for e in db.query(Enrollment).filter(Enrollment.student_id == current_user.id).all()
    ]

    if course_id is not None:
        if course_id not in enrolled_course_ids:
            return []
        enrolled_course_ids = [course_id]

    if not enrolled_course_ids:
        return []

    exams = db.query(Exam).filter(Exam.course_id.in_(enrolled_course_ids)).all()
    exam_ids = [exam.id for exam in exams]
    results = db.query(Result).filter(
        Result.student_id == current_user.id,
        Result.exam_id.in_(exam_ids) if exam_ids else False,
    ).all() if exam_ids else []
    result_by_exam_id = {result.exam_id: result for result in results}

    responses: List[StudentExamListResponse] = []
    for exam in exams:
        result = result_by_exam_id.get(exam.id)
        status = "completed" if result else "available"
        responses.append(
            StudentExamListResponse(
                id=exam.id,
                course_id=exam.course_id,
                course_title=exam.course.title if exam.course else "",
                title=exam.title,
                description=exam.description,
                questions_count=len(exam.questions),
                status=status,
                score=result.score if result else None,
            )
        )

    return responses


@router.get("/{exam_id}", response_model=ExamResponse)
async def get_exam(exam_id: int, db: Session = Depends(get_db)):
    """Get exam details with questions."""
    exam = db.query(Exam).filter(Exam.id == exam_id).first()
    if not exam:
        raise HTTPException(status_code=404, detail="Exam not found")
    
    return ExamResponse(
        id=exam.id,
        course_id=exam.course_id,
        title=exam.title,
        description=exam.description,
        questions=[QuestionResponse.model_validate(q) for q in exam.questions]
    )


@router.patch("/{exam_id}", response_model=ExamResponse)
async def update_exam(
    exam_id: int,
    exam_data: ExamUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update exam title/description (teachers only)."""
    if current_user.role != UserRole.TEACHER:
        raise HTTPException(status_code=403, detail="Only teachers can update exams")

    exam = db.query(Exam).filter(Exam.id == exam_id).first()
    if not exam:
        raise HTTPException(status_code=404, detail="Exam not found")

    if exam.course.teacher_id != current_user.id:
        raise HTTPException(status_code=403, detail="You can only edit your own exams")

    update_data = exam_data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(exam, key, value)

    db.commit()
    db.refresh(exam)

    return ExamResponse(
        id=exam.id,
        course_id=exam.course_id,
        title=exam.title,
        description=exam.description,
        questions=[QuestionResponse.model_validate(q) for q in exam.questions]
    )


@router.post("/{exam_id}/questions", response_model=QuestionResponse)
async def add_question(
    exam_id: int,
    question_data: QuestionCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Add a question to an exam (teachers only)."""
    if current_user.role != UserRole.TEACHER:
        raise HTTPException(status_code=403, detail="Only teachers can add questions")

    exam = db.query(Exam).filter(Exam.id == exam_id).first()
    if not exam:
        raise HTTPException(status_code=404, detail="Exam not found")
    if exam.course.teacher_id != current_user.id:
        raise HTTPException(status_code=403, detail="You can only edit your own exams")

    question = Question(
        exam_id=exam_id,
        question=question_data.question,
        option_a=question_data.option_a,
        option_b=question_data.option_b,
        option_c=question_data.option_c,
        option_d=question_data.option_d,
        correct_option=question_data.correct_option.lower()
    )
    db.add(question)
    db.commit()
    db.refresh(question)

    return QuestionResponse.model_validate(question)


@router.patch("/questions/{question_id}", response_model=QuestionResponse)
async def update_question(
    question_id: int,
    question_data: QuestionUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update a question (teachers only)."""
    if current_user.role != UserRole.TEACHER:
        raise HTTPException(status_code=403, detail="Only teachers can update questions")

    question = db.query(Question).filter(Question.id == question_id).first()
    if not question:
        raise HTTPException(status_code=404, detail="Question not found")

    exam = db.query(Exam).filter(Exam.id == question.exam_id).first()
    if not exam or exam.course.teacher_id != current_user.id:
        raise HTTPException(status_code=403, detail="You can only edit your own exams")

    update_data = question_data.model_dump(exclude_unset=True)
    if "correct_option" in update_data and update_data["correct_option"]:
        update_data["correct_option"] = update_data["correct_option"].lower()

    for key, value in update_data.items():
        setattr(question, key, value)

    db.commit()
    db.refresh(question)

    return QuestionResponse.model_validate(question)


@router.delete("/questions/{question_id}")
async def delete_question(
    question_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete a question (teachers only)."""
    if current_user.role != UserRole.TEACHER:
        raise HTTPException(status_code=403, detail="Only teachers can delete questions")

    question = db.query(Question).filter(Question.id == question_id).first()
    if not question:
        raise HTTPException(status_code=404, detail="Question not found")

    exam = db.query(Exam).filter(Exam.id == question.exam_id).first()
    if not exam or exam.course.teacher_id != current_user.id:
        raise HTTPException(status_code=403, detail="You can only edit your own exams")

    db.delete(question)
    db.commit()

    return {"detail": "Question deleted"}


@router.delete("/{exam_id}")
async def delete_exam(
    exam_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete an exam (teachers only)."""
    if current_user.role != UserRole.TEACHER:
        raise HTTPException(status_code=403, detail="Only teachers can delete exams")

    exam = db.query(Exam).filter(Exam.id == exam_id).first()
    if not exam:
        raise HTTPException(status_code=404, detail="Exam not found")

    if exam.course.teacher_id != current_user.id:
        raise HTTPException(status_code=403, detail="You can only delete your own exams")

    db.delete(exam)
    db.commit()
    return {"detail": "Exam deleted"}


@router.post("/{exam_id}/submit", response_model=ResultResponse)
async def submit_exam(
    exam_id: int,
    answers: ExamSubmit,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Submit exam answers and get results."""
    exam = db.query(Exam).filter(Exam.id == exam_id).first()
    if not exam:
        raise HTTPException(status_code=404, detail="Exam not found")
    
    # Check if already submitted
    existing_result = db.query(Result).filter(
        Result.exam_id == exam_id,
        Result.student_id == current_user.id
    ).first()
    if existing_result:
        raise HTTPException(status_code=400, detail="Exam already submitted")
    
    # Grade the exam
    questions = exam.questions
    total_questions = len(questions)
    correct_answers = 0
    
    for question in questions:
        selected_answer = answers.answers.get(question.id, "").lower()
        if selected_answer == question.correct_option.lower():
            correct_answers += 1
    
    score = (correct_answers / total_questions) * 100 if total_questions > 0 else 0
    
    # Save result
    result = Result(
        exam_id=exam_id,
        student_id=current_user.id,
        score=score,
        total_questions=total_questions,
        correct_answers=correct_answers
    )
    db.add(result)
    db.commit()
    db.refresh(result)
    
    return ResultResponse.model_validate(result)


@router.get("/{exam_id}/results", response_model=List[ResultResponse])
async def get_exam_results(
    exam_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get exam results (teachers see all, students see only their own)."""
    exam = db.query(Exam).filter(Exam.id == exam_id).first()
    if not exam:
        raise HTTPException(status_code=404, detail="Exam not found")
    
    if current_user.role == UserRole.TEACHER:
        if exam.course.teacher_id != current_user.id:
            raise HTTPException(status_code=403, detail="You can only view results for your own exams")
        results = db.query(Result).filter(Result.exam_id == exam_id).all()
    else:
        results = db.query(Result).filter(
            Result.exam_id == exam_id,
            Result.student_id == current_user.id
        ).all()
    
    return [ResultResponse.model_validate(result) for result in results]


@router.get("/{exam_id}/submissions", response_model=List[ResultWithStudentResponse])
async def get_exam_submissions(
    exam_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get exam submissions with student info (teachers only)."""
    exam = db.query(Exam).filter(Exam.id == exam_id).first()
    if not exam:
        raise HTTPException(status_code=404, detail="Exam not found")

    if current_user.role != UserRole.TEACHER or exam.course.teacher_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not allowed")

    results = db.query(Result).filter(Result.exam_id == exam_id).all()
    return [
        ResultWithStudentResponse(
            id=result.id,
            exam_id=result.exam_id,
            student_id=result.student_id,
            score=result.score,
            total_questions=result.total_questions,
            correct_answers=result.correct_answers,
            student_name=result.student.name if result.student else "",
            student_email=result.student.email if result.student else "",
        )
        for result in results
    ]

