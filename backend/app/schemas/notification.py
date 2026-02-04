from pydantic import BaseModel
from typing import Optional, Dict, List, Literal
from datetime import datetime


class NotificationTokenCreate(BaseModel):
    token: str
    device_type: Optional[str] = None


class NotificationTokenDelete(BaseModel):
    token: str


class NotificationTokenResponse(BaseModel):
    id: int
    user_id: int
    token: str
    device_type: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class NotificationSendRequest(BaseModel):
    title: str
    body: str
    data: Optional[Dict[str, str]] = None
    user_id: Optional[int] = None
    tokens: Optional[List[str]] = None
    target_role: Optional[Literal["teacher", "student", "all"]] = None
    send_push: bool = True
    send_in_app: bool = True


class NotificationSendResponse(BaseModel):
    success_count: int
    failure_count: int
    errors: Optional[List[str]] = None


class InAppNotificationResponse(BaseModel):
    id: int
    user_id: int
    title: str
    body: str
    data: Optional[Dict[str, str]] = None
    is_read: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class InAppNotificationCreate(BaseModel):
    title: str
    body: str
    data: Optional[Dict[str, str]] = None
    user_id: int


class InAppNotificationUpdate(BaseModel):
    is_read: bool
