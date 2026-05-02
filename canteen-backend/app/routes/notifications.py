from fastapi import APIRouter, Depends, HTTPException
from asyncpg import Connection
import json

from app.dependencies import get_current_user, get_db, require_staff
from app.schemas.common import MessageResponse
from app.schemas.notifications import NotificationCreateRequest, NotificationResponse

router = APIRouter(prefix="/api/notifications", tags=["notifications"])


@router.post("", response_model=MessageResponse)
async def create_notification(request: NotificationCreateRequest, db: Connection = Depends(get_db), staff: dict = Depends(require_staff)):
    if not any([request.user_id, request.hostel_id, request.role_id]):
        raise HTTPException(status_code=400, detail="Notification needs a user, hostel, or role target")

    notification_id = await db.fetchval(
        """
        INSERT INTO notifications (
            user_id, hostel_id, role_id, title, message, image_url, type, priority,
            action_label, action_route, action_params, reference_type, reference_id,
            scheduled_at, is_scheduled, expiry_at, created_by
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)
        RETURNING id
        """,
        request.user_id,
        request.hostel_id,
        request.role_id,
        request.title,
        request.message,
        request.image_url,
        request.type,
        request.priority,
        request.action_label,
        request.action_route,
        json.dumps(request.action_params) if request.action_params is not None else None,
        request.reference_type,
        request.reference_id,
        request.scheduled_at,
        request.scheduled_at is not None,
        request.expiry_at,
        staff["id"],
    )
    await _materialize_recipients(db, notification_id)
    return MessageResponse(message="Notification created")


async def _materialize_recipients(db: Connection, notification_id: int):
    notification = await db.fetchrow("SELECT user_id, hostel_id, role_id FROM notifications WHERE id = $1", notification_id)
    user_ids = set()
    if notification["user_id"]:
        user_ids.add(notification["user_id"])
    if notification["role_id"]:
        rows = await db.fetch("SELECT id FROM users WHERE role_id = $1 AND is_active = TRUE", notification["role_id"])
        user_ids.update(row["id"] for row in rows)
    if notification["hostel_id"]:
        rows = await db.fetch("SELECT user_id FROM students WHERE hostel_id = $1 AND is_active = TRUE", notification["hostel_id"])
        user_ids.update(row["user_id"] for row in rows)

    for user_id in user_ids:
        await db.execute(
            "INSERT INTO notification_recipients (notification_id, user_id, delivered_at) VALUES ($1, $2, CURRENT_TIMESTAMP) ON CONFLICT DO NOTHING",
            notification_id,
            user_id,
        )


@router.get("", response_model=list[NotificationResponse])
async def my_notifications(current_user: dict = Depends(get_current_user), db: Connection = Depends(get_db)):
    rows = await db.fetch(
        """
        SELECT n.id, n.title, n.message, n.type, n.priority, n.action_label, n.action_route,
               nr.is_read, nr.read_at::text, n.created_at::text
        FROM notification_recipients nr
        JOIN notifications n ON n.id = nr.notification_id
        WHERE nr.user_id = $1
          AND (n.expiry_at IS NULL OR n.expiry_at > CURRENT_TIMESTAMP)
        ORDER BY n.created_at DESC
        """,
        current_user["id"],
    )
    return [dict(row) for row in rows]


@router.put("/{notification_id}/read", response_model=MessageResponse)
async def mark_read(notification_id: int, current_user: dict = Depends(get_current_user), db: Connection = Depends(get_db)):
    result = await db.execute(
        """
        UPDATE notification_recipients
        SET is_read = TRUE, read_at = CURRENT_TIMESTAMP
        WHERE notification_id = $1 AND user_id = $2
        """,
        notification_id,
        current_user["id"],
    )
    if result.endswith("0"):
        raise HTTPException(status_code=404, detail="Notification not found")
    return MessageResponse(message="Notification marked as read")
