from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.core.database import get_db
from app.api.dependencies import get_current_user
from app.models.user import User, UserRole
from app.models.notification import NotificationToken, InAppNotification
from app.schemas.notification import (
    NotificationTokenCreate,
    NotificationTokenDelete,
    NotificationTokenResponse,
    NotificationSendRequest,
    NotificationSendResponse,
    InAppNotificationResponse,
    InAppNotificationCreate,
    InAppNotificationUpdate,
)
from app.services.notification_service import send_fcm_multicast
import json

router = APIRouter()


def _require_admin(current_user: User) -> None:
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="Admin access required")


@router.post("/tokens", response_model=NotificationTokenResponse)
def register_token(
    payload: NotificationTokenCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    existing = db.query(NotificationToken).filter(NotificationToken.token == payload.token).first()
    if existing:
        existing.user_id = current_user.id
        if payload.device_type is not None:
            existing.device_type = payload.device_type
        db.commit()
        db.refresh(existing)
        return existing

    token = NotificationToken(
        user_id=current_user.id,
        token=payload.token,
        device_type=payload.device_type,
    )
    db.add(token)
    db.commit()
    db.refresh(token)
    return token


@router.delete("/tokens")
def unregister_token(
    payload: NotificationTokenDelete,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    token = (
        db.query(NotificationToken)
        .filter(NotificationToken.token == payload.token)
        .filter(NotificationToken.user_id == current_user.id)
        .first()
    )
    if not token:
        raise HTTPException(status_code=404, detail="Token not found")

    db.delete(token)
    db.commit()
    return {"message": "Token removed"}


@router.post("/send", response_model=NotificationSendResponse)
def send_notification(
    payload: NotificationSendRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    _require_admin(current_user)

    tokens: List[str] = []
    if payload.tokens:
        tokens.extend(payload.tokens)

    if payload.user_id is not None:
        user_tokens = (
            db.query(NotificationToken)
            .filter(NotificationToken.user_id == payload.user_id)
            .all()
        )
        tokens.extend([t.token for t in user_tokens])

    tokens = list(dict.fromkeys(tokens))
    if not tokens:
        return NotificationSendResponse(success_count=0, failure_count=0, errors=None)

    try:
        user_ids = set()
        if payload.user_id is not None:
            user_ids.add(payload.user_id)
        if payload.tokens:
            token_users = (
                db.query(NotificationToken)
                .filter(NotificationToken.token.in_(payload.tokens))
                .all()
            )
            user_ids.update([t.user_id for t in token_users])

        result = send_fcm_multicast(
            tokens=tokens,
            title=payload.title,
            body=payload.body,
            data=payload.data,
        )

        if user_ids:
            data_json = json.dumps(payload.data) if payload.data else None
            for user_id in user_ids:
                db.add(
                    InAppNotification(
                        user_id=user_id,
                        title=payload.title,
                        body=payload.body,
                        data=data_json,
                    )
                )
            db.commit()

        return NotificationSendResponse(**result)
    except ValueError as exc:
        raise HTTPException(status_code=500, detail=str(exc))
    except RuntimeError as exc:
        raise HTTPException(status_code=502, detail=str(exc))


@router.post("/inapp", response_model=InAppNotificationResponse)
def create_inapp_notification(
    payload: InAppNotificationCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    _require_admin(current_user)

    data_json = json.dumps(payload.data) if payload.data else None
    notification = InAppNotification(
        user_id=payload.user_id,
        title=payload.title,
        body=payload.body,
        data=data_json,
    )
    db.add(notification)
    db.commit()
    db.refresh(notification)

    response = InAppNotificationResponse.model_validate(notification)
    response.data = payload.data
    return response


@router.get("/inapp", response_model=List[InAppNotificationResponse])
def list_inapp_notifications(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    notifications = (
        db.query(InAppNotification)
        .filter(InAppNotification.user_id == current_user.id)
        .order_by(InAppNotification.created_at.desc())
        .all()
    )

    results: List[InAppNotificationResponse] = []
    for item in notifications:
        data = json.loads(item.data) if item.data else None
        response = InAppNotificationResponse.model_validate(item)
        response.data = data
        results.append(response)
    return results


@router.patch("/inapp/{notification_id}", response_model=InAppNotificationResponse)
def update_inapp_notification(
    notification_id: int,
    payload: InAppNotificationUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    notification = (
        db.query(InAppNotification)
        .filter(InAppNotification.id == notification_id)
        .filter(InAppNotification.user_id == current_user.id)
        .first()
    )
    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found")

    notification.is_read = payload.is_read
    db.commit()
    db.refresh(notification)

    data = json.loads(notification.data) if notification.data else None
    response = InAppNotificationResponse.model_validate(notification)
    response.data = data
    return response
