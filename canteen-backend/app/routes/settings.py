from fastapi import APIRouter, Depends, HTTPException
from asyncpg import Connection

from app.dependencies import get_db, require_staff
from app.schemas.settings import HostelSettingsResponse, HostelSettingsUpdateRequest

router = APIRouter(prefix="/api/settings", tags=["settings"])


@router.get("/hostels", response_model=list[HostelSettingsResponse])
async def list_hostel_settings(db: Connection = Depends(get_db), staff: dict = Depends(require_staff)):
    rows = await db.fetch(
        """
        SELECT id, hostel_id, booking_window_days, advance_booking_hour, cancel_window_hours,
               max_skips_per_month, penalty_after_skips, penalty_type, penalty_amount,
               auto_book_enabled, auto_book_days, menu_publish_time, meal_cost, currency,
               default_notify_before, created_at::text, updated_at::text
        FROM hostel_settings
        ORDER BY hostel_id
        """
    )
    return [dict(row) for row in rows]


@router.put("/hostels/{hostel_id}", response_model=HostelSettingsResponse)
async def update_hostel_settings(hostel_id: int, request: HostelSettingsUpdateRequest, db: Connection = Depends(get_db), staff: dict = Depends(require_staff)):
    current = await db.fetchrow("SELECT * FROM hostel_settings WHERE hostel_id = $1", hostel_id)
    if not current:
        raise HTTPException(status_code=404, detail="Hostel settings not found")

    data = request.model_dump(exclude_unset=True)
    values = {
        "booking_window_days": data.get("booking_window_days", current["booking_window_days"]),
        "advance_booking_hour": data.get("advance_booking_hour", current["advance_booking_hour"]),
        "cancel_window_hours": data.get("cancel_window_hours", current["cancel_window_hours"]),
        "max_skips_per_month": data.get("max_skips_per_month", current["max_skips_per_month"]),
        "penalty_after_skips": data.get("penalty_after_skips", current["penalty_after_skips"]),
        "penalty_type": data.get("penalty_type", current["penalty_type"]),
        "penalty_amount": data.get("penalty_amount", current["penalty_amount"]),
        "auto_book_enabled": data.get("auto_book_enabled", current["auto_book_enabled"]),
        "auto_book_days": data.get("auto_book_days", current["auto_book_days"]),
        "menu_publish_time": data.get("menu_publish_time", current["menu_publish_time"]),
        "meal_cost": data.get("meal_cost", current["meal_cost"]),
        "currency": data.get("currency", current["currency"]),
        "default_notify_before": data.get("default_notify_before", current["default_notify_before"]),
    }
    row = await db.fetchrow(
        """
        UPDATE hostel_settings
        SET booking_window_days = $1, advance_booking_hour = $2, cancel_window_hours = $3,
            max_skips_per_month = $4, penalty_after_skips = $5, penalty_type = $6,
            penalty_amount = $7, auto_book_enabled = $8, auto_book_days = $9,
            menu_publish_time = $10, meal_cost = $11, currency = $12, default_notify_before = $13
        WHERE hostel_id = $14
        RETURNING id, hostel_id, booking_window_days, advance_booking_hour, cancel_window_hours,
                  max_skips_per_month, penalty_after_skips, penalty_type, penalty_amount,
                  auto_book_enabled, auto_book_days, menu_publish_time, meal_cost, currency,
                  default_notify_before, created_at::text, updated_at::text
        """,
        *values.values(),
        hostel_id,
    )
    return dict(row)
