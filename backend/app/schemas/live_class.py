from pydantic import BaseModel
from typing import Optional, Literal
from datetime import datetime

class LiveClassBase(BaseModel):
    title: str
    course_id: int
    scheduled_time: Optional[datetime] = None

class LiveClassCreate(LiveClassBase):
    pass

class LiveClassUpdate(BaseModel):
    status: Optional[Literal["scheduled", "active", "ended"]] = None
    started_at: Optional[datetime] = None
    ended_at: Optional[datetime] = None
    scheduled_time: Optional[datetime] = None
    title: Optional[str] = None

class LiveClassResponse(LiveClassBase):
    id: int
    teacher_id: int
    room_name: str
    status: str
    scheduled_time: Optional[datetime]
    started_at: Optional[datetime]
    ended_at: Optional[datetime]

    class Config:
        orm_mode = True
