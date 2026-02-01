from pydantic import BaseModel, EmailStr
from typing import Optional


class AdminStatsResponse(BaseModel):
    total_users: int
    total_students: int
    total_teachers: int
    total_admins: int
    total_courses: int
    total_content_items: int
    total_exams: int
    total_live_classes: int
    enrollments_total: int
    enrollments_pending: int
    enrollments_approved: int
    enrollments_rejected: int
    live_classes_scheduled: int
    live_classes_active: int
    live_classes_ended: int


class AdminAnalyticsResponse(BaseModel):
    enrollments_pending: int
    enrollments_approved: int
    enrollments_rejected: int
    live_classes_scheduled: int
    live_classes_active: int
    live_classes_ended: int


class AdminTrendsResponse(BaseModel):
    period: str
    labels: list[str]
    enrollments: list[int]
    live_classes: list[int]
    enrollments_change: float
    live_classes_change: float


class AdminTeacherCreate(BaseModel):
    name: str
    email: EmailStr
    password: str


class AdminTeacherUpdate(BaseModel):
    name: Optional[str] = None
    email: Optional[EmailStr] = None
    password: Optional[str] = None
