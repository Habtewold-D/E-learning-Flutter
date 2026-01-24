from sqlalchemy.orm import Session
from app.models.live_class import LiveClass, LiveClassStatus
from app.schemas.live_class import LiveClassCreate, LiveClassUpdate
from typing import List, Optional
from datetime import datetime
import secrets

# CRUD operations for LiveClass

def create_live_class(db: Session, teacher_id: int, data: LiveClassCreate) -> LiveClass:
    room_name = f"course-{data.course_id}-{secrets.token_urlsafe(8)}"
    live_class = LiveClass(
        title=data.title,
        course_id=data.course_id,
        teacher_id=teacher_id,
        room_name=room_name,
        status=LiveClassStatus.SCHEDULED,
        scheduled_time=data.scheduled_time
    )
    db.add(live_class)
    db.commit()
    db.refresh(live_class)
    return live_class

def get_live_class(db: Session, live_class_id: int) -> Optional[LiveClass]:
    return db.query(LiveClass).filter(LiveClass.id == live_class_id).first()

def list_live_classes(db: Session, course_id: Optional[int] = None, status: Optional[str] = None) -> List[LiveClass]:
    query = db.query(LiveClass)
    if course_id:
        query = query.filter(LiveClass.course_id == course_id)
    if status:
        query = query.filter(LiveClass.status == status)
    return query.order_by(LiveClass.scheduled_time.desc()).all()

def update_live_class(db: Session, live_class_id: int, data: LiveClassUpdate) -> Optional[LiveClass]:
    live_class = get_live_class(db, live_class_id)
    if not live_class:
        return None
    for field, value in data.dict(exclude_unset=True).items():
        setattr(live_class, field, value)
    db.commit()
    db.refresh(live_class)
    return live_class
