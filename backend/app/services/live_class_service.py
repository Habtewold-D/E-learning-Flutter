from sqlalchemy.orm import Session
from app.models.live_class import LiveClass, LiveClassStatus
from app.schemas.live_class import LiveClassCreate, LiveClassUpdate
from typing import List, Optional
from datetime import datetime, timedelta
import secrets

# CRUD operations for LiveClass

def create_live_class(db: Session, teacher_id: int, data: LiveClassCreate) -> LiveClass:
    room_name = f"course-{data.course_id}-{secrets.token_urlsafe(8)}"
    now = datetime.now()
    # If no scheduled_time or scheduled_time is now/past, start immediately
    start_immediately = data.scheduled_time is None or data.scheduled_time <= now

    live_class = LiveClass(
        title=data.title,
        course_id=data.course_id,
        teacher_id=teacher_id,
        room_name=room_name,
        status=LiveClassStatus.ACTIVE if start_immediately else LiveClassStatus.SCHEDULED,
        scheduled_time=data.scheduled_time,
        started_at=now if start_immediately else None,
    )
    db.add(live_class)
    db.commit()
    db.refresh(live_class)
    return live_class

def get_live_class(db: Session, live_class_id: int) -> Optional[LiveClass]:
    return db.query(LiveClass).filter(LiveClass.id == live_class_id).first()

def _auto_update_statuses(db: Session) -> None:
    """Promote scheduled → active at scheduled_time, and active → ended after 1 hour."""
    now = datetime.now()
    changed = False

    # Scheduled to active when time arrives (or scheduled_time missing but created)
    scheduled_classes = (
        db.query(LiveClass)
        .filter(
            LiveClass.status == LiveClassStatus.SCHEDULED,
        )
        .all()
    )
    for lc in scheduled_classes:
        if lc.scheduled_time is None or lc.scheduled_time <= now:
            lc.status = LiveClassStatus.ACTIVE
            lc.started_at = lc.started_at or now
            changed = True

    # Active to ended after 1 hour from the earliest known start (scheduled beats actual start)
    active_classes = db.query(LiveClass).filter(LiveClass.status == LiveClassStatus.ACTIVE).all()
    for lc in active_classes:
        base_time = lc.scheduled_time or lc.started_at
        if base_time and base_time + timedelta(hours=1) <= now:
            lc.status = LiveClassStatus.ENDED
            lc.ended_at = lc.ended_at or now
            changed = True

    if changed:
        db.commit()


def list_live_classes(
    db: Session,
    course_id: Optional[int] = None,
    status: Optional[str] = None,
    teacher_id: Optional[int] = None,
) -> List[LiveClass]:
    _auto_update_statuses(db)
    query = db.query(LiveClass)
    if course_id:
        query = query.filter(LiveClass.course_id == course_id)
    if status:
        query = query.filter(LiveClass.status == status)
    if teacher_id:
        query = query.filter(LiveClass.teacher_id == teacher_id)
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

def refresh_live_class_status(db: Session, live_class_id: int) -> Optional[LiveClass]:
    """Update status for a single class based on time rules and return it."""
    _auto_update_statuses(db)
    return get_live_class(db, live_class_id)
