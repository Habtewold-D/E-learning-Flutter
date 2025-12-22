from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from app.core.database import get_db
from app.models.user import User, UserRole
from app.api.dependencies import get_current_user
import secrets

router = APIRouter()


class RoomResponse(BaseModel):
    room_name: str
    room_url: str


@router.post("/create-room", response_model=RoomResponse)
async def create_live_room(
    course_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create a live class room (teachers only)."""
    if current_user.role != UserRole.TEACHER:
        raise HTTPException(status_code=403, detail="Only teachers can create live rooms")
    
    # Generate a unique room name
    room_name = f"course-{course_id}-{secrets.token_urlsafe(8)}"
    
    # For Jitsi Meet, the URL format is simple
    room_url = f"https://meet.jit.si/{room_name}"
    
    return RoomResponse(room_name=room_name, room_url=room_url)


@router.get("/join-room/{room_name}", response_model=RoomResponse)
async def get_room_url(room_name: str):
    """Get the Jitsi Meet URL for a room."""
    room_url = f"https://meet.jit.si/{room_name}"
    return RoomResponse(room_name=room_name, room_url=room_url)

