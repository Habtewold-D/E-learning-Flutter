import json
from typing import Dict, Any, List, Optional
import requests
from google.oauth2 import service_account
from google.auth.transport.requests import Request
from app.core.config import settings
from sqlalchemy.orm import Session
from app.models.notification import NotificationToken, InAppNotification


FIREBASE_MESSAGING_SCOPE = "https://www.googleapis.com/auth/firebase.messaging"


def _load_service_account_info() -> Dict[str, Any]:
    raw = settings.FIREBASE_SERVICE_ACCOUNT_JSON
    if not raw:
        raise ValueError("FIREBASE_SERVICE_ACCOUNT_JSON is not set")

    raw = raw.strip()
    if (raw.startswith("'") and raw.endswith("'")) or (raw.startswith('"') and raw.endswith('"')):
        raw = raw[1:-1]

    info = json.loads(raw)

    private_key = info.get("private_key")
    if isinstance(private_key, str) and "\\n" in private_key:
        info["private_key"] = private_key.replace("\\n", "\n")

    return info


def _get_access_token() -> tuple[str, str]:
    info = _load_service_account_info()
    project_id = info.get("project_id")
    if not project_id:
        raise ValueError("project_id missing from service account JSON")

    credentials = service_account.Credentials.from_service_account_info(
        info,
        scopes=[FIREBASE_MESSAGING_SCOPE],
    )
    credentials.refresh(Request())
    return credentials.token, project_id


def send_fcm_message(
    token: str,
    title: str,
    body: str,
    data: Optional[Dict[str, str]] = None,
) -> Dict[str, Any]:
    access_token, project_id = _get_access_token()

    url = f"https://fcm.googleapis.com/v1/projects/{project_id}/messages:send"

    message: Dict[str, Any] = {
        "message": {
            "token": token,
            "notification": {
                "title": title,
                "body": body,
            },
        }
    }

    if data:
        message["message"]["data"] = {str(k): str(v) for k, v in data.items()}

    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json; UTF-8",
    }

    response = requests.post(url, headers=headers, json=message, timeout=15)
    if response.status_code >= 400:
        raise RuntimeError(f"FCM send failed: {response.status_code} {response.text}")

    return response.json()


def send_fcm_multicast(
    tokens: List[str],
    title: str,
    body: str,
    data: Optional[Dict[str, str]] = None,
) -> Dict[str, Any]:
    success_count = 0
    failure_count = 0
    errors: List[str] = []

    for token in tokens:
        try:
            send_fcm_message(token=token, title=title, body=body, data=data)
            success_count += 1
        except Exception as exc:
            failure_count += 1
            errors.append(str(exc))

    return {
        "success_count": success_count,
        "failure_count": failure_count,
        "errors": errors or None,
    }


def notify_users(
    db: Session,
    user_ids: List[int],
    title: str,
    body: str,
    data: Optional[Dict[str, str]] = None,
    send_push: bool = True,
) -> Dict[str, Any]:
    if not user_ids:
        return {"success_count": 0, "failure_count": 0, "errors": None}

    unique_user_ids = list(dict.fromkeys(user_ids))
    data_json = json.dumps(data) if data else None

    for user_id in unique_user_ids:
        db.add(
            InAppNotification(
                user_id=user_id,
                title=title,
                body=body,
                data=data_json,
            )
        )
    db.commit()

    if not send_push or not settings.FIREBASE_SERVICE_ACCOUNT_JSON:
        return {"success_count": 0, "failure_count": 0, "errors": None}

    tokens = (
        db.query(NotificationToken)
        .filter(NotificationToken.user_id.in_(unique_user_ids))
        .all()
    )
    token_values = [t.token for t in tokens]
    if not token_values:
        return {"success_count": 0, "failure_count": 0, "errors": None}

    try:
        return send_fcm_multicast(
            tokens=token_values,
            title=title,
            body=body,
            data=data,
        )
    except Exception as exc:
        return {"success_count": 0, "failure_count": len(token_values), "errors": [str(exc)]}
