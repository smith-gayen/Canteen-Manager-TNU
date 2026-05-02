from datetime import time
from pydantic import BaseModel, Field


class StaffCreateRequest(BaseModel):
    email: str
    password: str = Field(..., min_length=8)
    first_name: str
    last_name: str
    phone: str | None = None
    designation: str
    hostel_id: int | None = None
    can_scan_qr: bool = False
    can_edit_menu: bool = False
    can_view_reports: bool = False
    can_manage_staff: bool = False
    shift_start: time | None = None
    shift_end: time | None = None


class StaffUpdateRequest(BaseModel):
    phone: str | None = None
    designation: str | None = None
    hostel_id: int | None = None
    can_scan_qr: bool | None = None
    can_edit_menu: bool | None = None
    can_view_reports: bool | None = None
    can_manage_staff: bool | None = None
    shift_start: time | None = None
    shift_end: time | None = None
    is_active: bool | None = None


class StaffResponse(BaseModel):
    id: int
    user_id: int
    email: str
    first_name: str
    last_name: str
    phone: str | None = None
    designation: str | None = None
    hostel_id: int | None = None
    can_scan_qr: bool
    can_edit_menu: bool
    can_view_reports: bool
    can_manage_staff: bool
    is_active: bool
