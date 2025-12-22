from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.core.database import get_db
from app.models.user import User, UserRole
from app.models.course import Course
from app.models.exam import Exam, Question, Result
from app.schemas.exam import ExamCreate, ExamResponse, ExamSubmit, ResultResponse, QuestionResponse
from app.api.dependencies import get_current_user

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

