from datetime import time
from decimal import Decimal
from pydantic import BaseModel, Field


class HostelSettingsUpdateRequest(BaseModel):
    booking_window_days: int | None = Field(default=None, ge=1, le=30)
    advance_booking_hour: int | None = Field(default=None, ge=0, le=23)
    cancel_window_hours: int | None = Field(default=None, ge=0)
    max_skips_per_month: int | None = Field(default=None, ge=0)
    penalty_after_skips: int | None = Field(default=None, ge=0)
    penalty_type: str | None = None
    penalty_amount: Decimal | None = None
    auto_book_enabled: bool | None = None
    auto_book_days: list[int] | None = None
    menu_publish_time: time | None = None
    meal_cost: Decimal | None = None
    currency: str | None = None
    default_notify_before: int | None = None


class HostelSettingsResponse(BaseModel):
    id: int
    hostel_id: int
    booking_window_days: int
    advance_booking_hour: int
    cancel_window_hours: int
    max_skips_per_month: int
    penalty_after_skips: int
    penalty_type: str
    penalty_amount: Decimal
    auto_book_enabled: bool
    auto_book_days: list[int]
    menu_publish_time: time
    meal_cost: Decimal
    currency: str
    default_notify_before: int
    created_at: str | None = None
    updated_at: str | None = None
