from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from app.core.database import get_db
from app.models.user import User, UserRole
from app.models.course import Course, Enrollment, EnrollmentStatus
from app.api.dependencies import get_current_user
from app.schemas.live_class import LiveClassCreate, LiveClassUpdate, LiveClassResponse
from app.core.config import settings
from app.services.live_class_service import (
    create_live_class,
    get_live_class,
    list_live_classes,
    update_live_class,
    refresh_live_class_status,
)
from app.services.notification_service import notify_users
from app.models.live_class import LiveClassStatus
from datetime import datetime, timedelta
import time
from jose import jwt

router = APIRouter(prefix="/live-classes", tags=["Live Classes"])

@router.post("/", response_model=LiveClassResponse)
def schedule_live_class(
    data: LiveClassCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.role != UserRole.TEACHER:
        raise HTTPException(status_code=403, detail="Only teachers can schedule live classes")
    live_class = create_live_class(db, teacher_id=current_user.id, data=data)

    try:
        course = db.query(Course).filter(Course.id == data.course_id).first()
        approved_students = (
            db.query(Enrollment)
            .filter(Enrollment.course_id == data.course_id)
            .filter(Enrollment.status == EnrollmentStatus.APPROVED)
            .all()
        )
        student_ids = [e.student_id for e in approved_students]
        notify_users(
            db=db,
            user_ids=student_ids,
            title="Live class scheduled",
            body=f"{course.title if course else 'Course'}: {live_class.title}",
            data={
                "type": "live_class_scheduled",
                "course_id": str(data.course_id),
                "live_class_id": str(live_class.id),
            },
        )
    except Exception:
        pass

    return live_class
@router.get("/{live_class_id}/join", response_model=LiveClassResponse)
def join_live_class(
    live_class_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    live_class = refresh_live_class_status(db, live_class_id)
    if not live_class:
        raise HTTPException(status_code=404, detail="Live class not found")
    now = datetime.now()
    if live_class.status != LiveClassStatus.ACTIVE:
        if current_user.role != UserRole.TEACHER or live_class.teacher_id != current_user.id:
            raise HTTPException(status_code=403, detail="Class has not started yet. Please wait for the teacher.")
        if live_class.scheduled_time:
            earliest_start = live_class.scheduled_time - timedelta(minutes=5)
            if now < earliest_start:
                raise HTTPException(
                    status_code=403,
                    detail="You can start this class within 5 minutes of its scheduled time",
                )
        # Teacher can start by joining if time rules allow
        live_class.status = LiveClassStatus.ACTIVE
        live_class.started_at = live_class.started_at or now
        db.commit()
        db.refresh(live_class)
    return live_class

@router.get("/", response_model=List[LiveClassResponse])
def get_live_classes(
    course_id: Optional[int] = None,
    status: Optional[LiveClassStatus] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return list_live_classes(db, course_id=course_id, status=status)

@router.get("/{live_class_id}", response_model=LiveClassResponse)
def get_live_class_detail(
    live_class_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    live_class = refresh_live_class_status(db, live_class_id)
    if not live_class:
        raise HTTPException(status_code=404, detail="Live class not found")
    return live_class

@router.patch("/{live_class_id}", response_model=LiveClassResponse)
def update_live_class_status(
    live_class_id: int,
    data: LiveClassUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    live_class = refresh_live_class_status(db, live_class_id)
    if not live_class:
        raise HTTPException(status_code=404, detail="Live class not found")
    # Only teacher who created the class can update
    if live_class.teacher_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not allowed")
    now = datetime.now()

    # Enforce timing: allow starting up to 5 minutes before scheduled_time
    if data.status == LiveClassStatus.ACTIVE or data.status == LiveClassStatus.ACTIVE.value:
        if live_class.status == LiveClassStatus.ENDED:
            raise HTTPException(status_code=400, detail="Class already ended")
        if live_class.scheduled_time:
            earliest_start = live_class.scheduled_time - timedelta(minutes=5)
            if now < earliest_start:
                raise HTTPException(
                    status_code=403,
                    detail="You can start this class within 5 minutes of its scheduled time",
                )
        data.started_at = data.started_at or now

    if data.status == LiveClassStatus.ENDED or data.status == LiveClassStatus.ENDED.value:
        data.ended_at = data.ended_at or now

    return update_live_class(db, live_class_id, data)


@router.get("/{live_class_id}/jaas-token")
def get_jaas_token(
    live_class_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if not settings.JAAS_APP_ID or not settings.JAAS_PRIVATE_KEY or not settings.JAAS_API_KEY:
        raise HTTPException(status_code=500, detail="JaaS is not configured")

    live_class = get_live_class(db, live_class_id)
    if not live_class:
        raise HTTPException(status_code=404, detail="Live class not found")

    room_name = live_class.room_name
    app_id = settings.JAAS_APP_ID

    now_ts = int(time.time())
    exp_ts = now_ts + 2 * 60 * 60
    nbf_ts = now_ts - 10

    payload = {
        "iss": "chat",
        "aud": "jitsi",
        "sub": app_id,
        "room": room_name,
        "exp": exp_ts,
        "nbf": nbf_ts,
        "iat": now_ts,
        "context": {
            "user": {
                "name": current_user.name,
                "email": current_user.email,
                "moderator": current_user.role == UserRole.TEACHER,
                "id": str(current_user.id),
            },
            "features": {
                "livestreaming": True,
                "recording": True,
                "transcription": True,
                "outbound-call": False,
            },
        },
    }

    private_key = settings.JAAS_PRIVATE_KEY.replace("\\n", "\n")
    token = jwt.encode(
        payload,
        private_key,
        algorithm="RS256",
        headers={"kid": settings.JAAS_API_KEY},
    )

    return {
        "token": token,
        "room": f"{app_id}/{room_name}",
        "server_url": "https://8x8.vc",
    }
