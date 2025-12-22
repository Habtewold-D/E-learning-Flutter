from pydantic import BaseModel
from typing import List, Optional
from app.models.course import ContentType


class CourseCreate(BaseModel):
    title: str
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

