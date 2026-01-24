from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from app.core.database import get_db
from app.models.user import User, UserRole
from app.api.dependencies import get_current_user
from app.schemas.live_class import LiveClassCreate, LiveClassUpdate, LiveClassResponse
from app.services.live_class_service import (
    create_live_class, get_live_class, list_live_classes, update_live_class
)
from app.models.live_class import LiveClassStatus
from datetime import datetime

router = APIRouter(prefix="/live-classes", tags=["Live Classes"])

@router.post("/", response_model=LiveClassResponse)
def schedule_live_class(
    data: LiveClassCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.role != UserRole.TEACHER:
        raise HTTPException(status_code=403, detail="Only teachers can schedule live classes")
    return create_live_class(db, teacher_id=current_user.id, data=data)
@router.get("/{live_class_id}/join", response_model=LiveClassResponse)
def join_live_class(
    live_class_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    live_class = get_live_class(db, live_class_id)
    if not live_class:
        raise HTTPException(status_code=404, detail="Live class not found")
    now = datetime.utcnow()
    if live_class.status != LiveClassStatus.ACTIVE:
        if not live_class.scheduled_time or now < live_class.scheduled_time:
            raise HTTPException(status_code=403, detail="Class has not started yet. Please wait for the teacher.")
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
    live_class = get_live_class(db, live_class_id)
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
    live_class = get_live_class(db, live_class_id)
    if not live_class:
        raise HTTPException(status_code=404, detail="Live class not found")
    # Only teacher who created the class can update
    if live_class.teacher_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not allowed")
    return update_live_class(db, live_class_id, data)
