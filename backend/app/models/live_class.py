from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Enum
from sqlalchemy.orm import relationship
import enum
from app.core.database import Base

class LiveClassStatus(str, enum.Enum):
    SCHEDULED = "scheduled"
    ACTIVE = "active"
    ENDED = "ended"

class LiveClass(Base):
    __tablename__ = "live_classes"

    id = Column(Integer, primary_key=True, index=True)
    course_id = Column(Integer, ForeignKey("courses.id"), nullable=False)
    teacher_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    title = Column(String, nullable=False)
    room_name = Column(String, unique=True, nullable=False)
    status = Column(Enum(LiveClassStatus), nullable=False, default=LiveClassStatus.SCHEDULED)
    scheduled_time = Column(DateTime, nullable=True)
    started_at = Column(DateTime, nullable=True)
    ended_at = Column(DateTime, nullable=True)

    course = relationship("Course", back_populates="live_classes")
    teacher = relationship("User")
