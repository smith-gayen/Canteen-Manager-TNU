from __future__ import annotations

from decimal import Decimal
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import date as Date, time as Time

class MealSlotResp(BaseModel):
    id: int
    name: str
    start_time: Time
    end_time: Time
    booking_cutoff_time: Time
    cancel_cutoff_time: Optional[Time]
    color_code: str
    icon_name: str

class MenuItemResp(BaseModel):
    id: int
    name: str
    description: Optional[str]
    is_veg: bool
    exclusive_group: Optional[str]

class MealMenuResp(BaseModel):
    id: int
    slot_id: int
    date: Date
    items: List[MenuItemResp]

class TodayResp(BaseModel):
    current_phase: str
    next_meal: str
    cutoff_time: Time
    countdown_hours: int
    countdown_minutes: int

class MenuItemCreateRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    type: str
    description: str | None = None
    short_description: str | None = None
    allergens: str | None = None
    spice_level: int | None = Field(default=None, ge=0, le=3)
    default_quantity: str = "1 plate"
    unit: str = "plate"
    base_price: Decimal = Decimal("0.00")
    is_premium: bool = False

class MealMenuItemRequest(BaseModel):
    menu_item_id: int
    quantity: str = "1 plate"
    quantity_value: Decimal = Decimal("1")
    unit: str = "plate"
    is_default: bool = False
    is_optional: bool = True
    max_selectable: int = 1
    price_override: Decimal | None = None
    sort_order: int = 0
    exclusive_group: str | None = None

class MealMenuCreateRequest(BaseModel):
    hostel_id: int
    meal_slot_id: int
    date: Date | None = None
    day_of_week: int | None = Field(default=None, ge=0, le=6)
    is_recurring: bool = False
    is_published: bool = False
    max_bookings: int = 999
    special_notes: str | None = None
    items: list[MealMenuItemRequest] = []
