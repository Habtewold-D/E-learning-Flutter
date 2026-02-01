from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.core.database import get_db
from app.api.dependencies import get_current_user
from app.models.user import User, UserRole
from app.models.course import Course, CourseContent, Enrollment, EnrollmentStatus
from app.models.exam import Exam
from app.models.live_class import LiveClass, LiveClassStatus
from app.schemas.user import UserResponse
from app.schemas.admin import (
    AdminStatsResponse,
    AdminAnalyticsResponse,
    AdminTrendsResponse,
    AdminTeacherCreate,
    AdminTeacherUpdate,
)
from datetime import datetime, timedelta
from app.core.security import get_password_hash

router = APIRouter()


def _require_admin(current_user: User) -> None:
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="Admin access required")


@router.get("/stats", response_model=AdminStatsResponse)
async def get_admin_stats(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    _require_admin(current_user)

    total_users = db.query(User).count()
    total_students = db.query(User).filter(User.role == UserRole.STUDENT).count()
    total_teachers = db.query(User).filter(User.role == UserRole.TEACHER).count()
    total_admins = db.query(User).filter(User.role == UserRole.ADMIN).count()

    total_courses = db.query(Course).count()
    total_content_items = db.query(CourseContent).count()
    total_exams = db.query(Exam).count()
    total_live_classes = db.query(LiveClass).count()

    enrollments_total = db.query(Enrollment).count()
    enrollments_pending = db.query(Enrollment).filter(Enrollment.status == EnrollmentStatus.PENDING).count()
    enrollments_approved = db.query(Enrollment).filter(Enrollment.status == EnrollmentStatus.APPROVED).count()
    enrollments_rejected = db.query(Enrollment).filter(Enrollment.status == EnrollmentStatus.REJECTED).count()

    live_classes_scheduled = db.query(LiveClass).filter(LiveClass.status == LiveClassStatus.SCHEDULED).count()
    live_classes_active = db.query(LiveClass).filter(LiveClass.status == LiveClassStatus.ACTIVE).count()
    live_classes_ended = db.query(LiveClass).filter(LiveClass.status == LiveClassStatus.ENDED).count()

    return AdminStatsResponse(
        total_users=total_users,
        total_students=total_students,
        total_teachers=total_teachers,
        total_admins=total_admins,
        total_courses=total_courses,
        total_content_items=total_content_items,
        total_exams=total_exams,
        total_live_classes=total_live_classes,
        enrollments_total=enrollments_total,
        enrollments_pending=enrollments_pending,
        enrollments_approved=enrollments_approved,
        enrollments_rejected=enrollments_rejected,
        live_classes_scheduled=live_classes_scheduled,
        live_classes_active=live_classes_active,
        live_classes_ended=live_classes_ended,
    )


@router.get("/analytics", response_model=AdminAnalyticsResponse)
async def get_admin_analytics(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    _require_admin(current_user)

    return AdminAnalyticsResponse(
        enrollments_pending=db.query(Enrollment).filter(Enrollment.status == EnrollmentStatus.PENDING).count(),
        enrollments_approved=db.query(Enrollment).filter(Enrollment.status == EnrollmentStatus.APPROVED).count(),
        enrollments_rejected=db.query(Enrollment).filter(Enrollment.status == EnrollmentStatus.REJECTED).count(),
        live_classes_scheduled=db.query(LiveClass).filter(LiveClass.status == LiveClassStatus.SCHEDULED).count(),
        live_classes_active=db.query(LiveClass).filter(LiveClass.status == LiveClassStatus.ACTIVE).count(),
        live_classes_ended=db.query(LiveClass).filter(LiveClass.status == LiveClassStatus.ENDED).count(),
    )


@router.get("/analytics/trends", response_model=AdminTrendsResponse)
async def get_admin_trends(
    period: str = "weekly",
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    _require_admin(current_user)

    now = datetime.utcnow()
    if period == "weekly":
        bucket_count = 7
        start_date = now - timedelta(days=bucket_count - 1)
        formatter = lambda d: d.strftime("%a")
        step = timedelta(days=1)
    elif period == "monthly":
        bucket_count = 12
        start_date = now.replace(day=1) - timedelta(days=365)
        formatter = lambda d: d.strftime("%b")
        step = None
    else:
        period = "yearly"
        bucket_count = 5
        start_date = now.replace(month=1, day=1) - timedelta(days=365 * (bucket_count - 1))
        formatter = lambda d: d.strftime("%Y")
        step = None

    labels: list[str] = []
    buckets: list[datetime] = []
    if period == "weekly":
        for i in range(bucket_count):
            day = (start_date + timedelta(days=i)).replace(hour=0, minute=0, second=0, microsecond=0)
            buckets.append(day)
            labels.append(formatter(day))
    elif period == "monthly":
        cursor = start_date.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        for _ in range(bucket_count):
            buckets.append(cursor)
            labels.append(formatter(cursor))
            if cursor.month == 12:
                cursor = cursor.replace(year=cursor.year + 1, month=1)
            else:
                cursor = cursor.replace(month=cursor.month + 1)
    else:
        cursor = start_date.replace(month=1, day=1, hour=0, minute=0, second=0, microsecond=0)
        for _ in range(bucket_count):
            buckets.append(cursor)
            labels.append(formatter(cursor))
            cursor = cursor.replace(year=cursor.year + 1)

    enrollments_series = [0] * bucket_count
    live_classes_series = [0] * bucket_count

    enrollments = db.query(Enrollment).filter(Enrollment.enrolled_at >= buckets[0]).all()
    for enrollment in enrollments:
        dt = enrollment.enrolled_at
        if period == "weekly":
            index = (dt.date() - buckets[0].date()).days
        elif period == "monthly":
            index = (dt.year - buckets[0].year) * 12 + (dt.month - buckets[0].month)
        else:
            index = dt.year - buckets[0].year
        if 0 <= index < bucket_count:
            enrollments_series[index] += 1

    live_classes = (
        db.query(LiveClass)
        .filter(LiveClass.scheduled_time.isnot(None))
        .filter(LiveClass.scheduled_time >= buckets[0])
        .all()
    )
    for live_class in live_classes:
        dt = live_class.scheduled_time
        if not dt:
            continue
        if period == "weekly":
            index = (dt.date() - buckets[0].date()).days
        elif period == "monthly":
            index = (dt.year - buckets[0].year) * 12 + (dt.month - buckets[0].month)
        else:
            index = dt.year - buckets[0].year
        if 0 <= index < bucket_count:
            live_classes_series[index] += 1

    half = bucket_count // 2
    current_enrollments = sum(enrollments_series[half:])
    previous_enrollments = sum(enrollments_series[:half])
    current_live = sum(live_classes_series[half:])
    previous_live = sum(live_classes_series[:half])

    def percent_change(current: int, previous: int) -> float:
        if previous == 0:
            return 100.0 if current > 0 else 0.0
        return ((current - previous) / previous) * 100

    return AdminTrendsResponse(
        period=period,
        labels=labels,
        enrollments=enrollments_series,
        live_classes=live_classes_series,
        enrollments_change=percent_change(current_enrollments, previous_enrollments),
        live_classes_change=percent_change(current_live, previous_live),
    )


@router.get("/teachers", response_model=List[UserResponse])
async def list_teachers(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    _require_admin(current_user)
    teachers = db.query(User).filter(User.role == UserRole.TEACHER).all()
    return [UserResponse.model_validate(teacher) for teacher in teachers]


@router.post("/teachers", response_model=UserResponse)
async def create_teacher(
    payload: AdminTeacherCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    _require_admin(current_user)

    existing = db.query(User).filter(User.email == payload.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")

    user = User(
        name=payload.name,
        email=payload.email,
        password=get_password_hash(payload.password),
        role=UserRole.TEACHER,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return UserResponse.model_validate(user)


@router.patch("/teachers/{teacher_id}", response_model=UserResponse)
async def update_teacher(
    teacher_id: int,
    payload: AdminTeacherUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    _require_admin(current_user)

    teacher = db.query(User).filter(User.id == teacher_id, User.role == UserRole.TEACHER).first()
    if not teacher:
        raise HTTPException(status_code=404, detail="Teacher not found")

    if payload.email is not None and payload.email != teacher.email:
        existing = db.query(User).filter(User.email == payload.email).first()
        if existing:
            raise HTTPException(status_code=400, detail="Email already registered")
        teacher.email = payload.email

    if payload.name is not None:
        teacher.name = payload.name

    if payload.password is not None:
        teacher.password = get_password_hash(payload.password)

    db.commit()
    db.refresh(teacher)
    return UserResponse.model_validate(teacher)


@router.delete("/teachers/{teacher_id}")
async def delete_teacher(
    teacher_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    _require_admin(current_user)

    teacher = db.query(User).filter(User.id == teacher_id, User.role == UserRole.TEACHER).first()
    if not teacher:
        raise HTTPException(status_code=404, detail="Teacher not found")

    db.delete(teacher)
    db.commit()
    return {"message": "Teacher deleted"}
