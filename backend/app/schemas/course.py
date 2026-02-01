from pydantic import BaseModel
from typing import List, Optional
from app.models.course import ContentType, EnrollmentStatus


class CourseCreate(BaseModel):
    title: str
    description: Optional[str] = None


class CourseUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None


class CourseResponse(BaseModel):
    id: int
    title: str
    description: Optional[str]
    teacher_id: int

    class Config:
        from_attributes = True


class ContentCreate(BaseModel):
    type: ContentType
    title: str
    url: str


class ContentResponse(BaseModel):
    id: int
    course_id: int
    type: ContentType
    title: str
    url: str

    class Config:
        from_attributes = True


class CourseWithContent(CourseResponse):
    contents: List[ContentResponse] = []


class EnrollmentResponse(BaseModel):
    course_id: int
    student_id: int
    enrolled_at: Optional[str] = None
    status: EnrollmentStatus = EnrollmentStatus.PENDING


class EnrollmentRequestResponse(BaseModel):
    id: int
    course_id: int
    course_title: str
    student_id: int
    student_name: str
    student_email: str
    status: EnrollmentStatus
    requested_at: Optional[str] = None


class CourseBrowseResponse(BaseModel):
    id: int
    title: str
    description: Optional[str]
    teacher_id: int
    teacher_name: str
    students_count: int
    content_count: int
    is_enrolled: bool
    enrollment_status: Optional[EnrollmentStatus] = None


class EnrolledCourseResponse(BaseModel):
    id: int
    title: str
    description: Optional[str]
    content_count: int
    completed_content: int
    progress: float


class CourseProgressResponse(BaseModel):
    course_id: int
    content_count: int
    completed_count: int
    progress: float
    completed_content_ids: List[int]


class StudentSummary(BaseModel):
    id: int
    name: str
    email: str

