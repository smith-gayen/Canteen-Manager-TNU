from datetime import datetime
from typing import Any
from pydantic import BaseModel, Field


class NotificationCreateRequest(BaseModel):
    user_id: int | None = None
    hostel_id: int | None = None
    role_id: int | None = None
    title: str = Field(..., min_length=2, max_length=100)
    message: str = Field(..., min_length=2)
    image_url: str | None = None
    type: str = "system"
    priority: str = "normal"
    action_label: str = "View"
    action_route: str | None = None
    action_params: dict[str, Any] | None = None
    reference_type: str | None = None
    reference_id: int | None = None
    scheduled_at: datetime | None = None
    expiry_at: datetime | None = None


class NotificationResponse(BaseModel):
    id: int
    title: str
    message: str
    type: str | None = None
    priority: str
    action_label: str | None = None
    action_route: str | None = None
    is_read: bool | None = None
    read_at: str | None = None
    created_at: str | None = None
