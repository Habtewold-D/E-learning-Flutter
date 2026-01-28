from pydantic import BaseModel
from typing import List, Optional


class QuestionCreate(BaseModel):
    question: str
    option_a: str
    option_b: str
    option_c: str
    option_d: str
    correct_option: str  # 'a', 'b', 'c', or 'd'


class QuestionResponse(BaseModel):
    id: int
    exam_id: int
    question: str
    option_a: str
    option_b: str
    option_c: str
    option_d: str
    correct_option: str

    class Config:
        from_attributes = True


class ExamCreate(BaseModel):
    course_id: int
    title: str
    description: Optional[str] = None
    questions: List[QuestionCreate]


class ExamUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None


class QuestionUpdate(BaseModel):
    question: Optional[str] = None
    option_a: Optional[str] = None
    option_b: Optional[str] = None
    option_c: Optional[str] = None
    option_d: Optional[str] = None
    correct_option: Optional[str] = None


class ExamResponse(BaseModel):
    id: int
    course_id: int
    title: str
    description: Optional[str]
    questions: List[QuestionResponse] = []

    class Config:
        from_attributes = True


class ExamSubmit(BaseModel):
    answers: dict[int, str]  # {question_id: selected_option}


class ResultResponse(BaseModel):
    id: int
    exam_id: int
    student_id: int
    score: float
    total_questions: int
    correct_answers: int

    class Config:
        from_attributes = True


class ResultWithStudentResponse(ResultResponse):
    student_name: str
    student_email: str

