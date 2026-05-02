from datetime import date
from pydantic import BaseModel, Field


class LeaveCreateRequest(BaseModel):
    start_date: date
    end_date: date
    reason: str = Field(..., min_length=2)
    reason_category: str = "home_visit"


class LeaveDecisionRequest(BaseModel):
    is_approved: bool


class LeaveResponse(BaseModel):
    id: int
    student_id: int
    start_date: date
    end_date: date
    reason: str
    reason_category: str
    is_approved: bool
    approved_by: int | None = None
    approved_at: str | None = None
    created_at: str | None = None
    updated_at: str | None = None
