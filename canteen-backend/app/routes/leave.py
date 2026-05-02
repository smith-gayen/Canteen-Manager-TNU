from fastapi import APIRouter, Depends, HTTPException
from asyncpg import Connection

from app.dependencies import get_current_student, get_db, require_staff
from app.schemas.common import MessageResponse
from app.schemas.leave import LeaveCreateRequest, LeaveDecisionRequest, LeaveResponse

router = APIRouter(prefix="/api/leave", tags=["leave"])


@router.post("", response_model=LeaveResponse)
async def create_leave(request: LeaveCreateRequest, db: Connection = Depends(get_db), student: dict = Depends(get_current_student)):
    row = await db.fetchrow(
        """
        INSERT INTO leave_periods (student_id, start_date, end_date, reason, reason_category)
        VALUES ($1, $2, $3, $4, $5)
        RETURNING id, student_id, start_date, end_date, reason, reason_category, is_approved,
                  approved_by, approved_at::text, created_at::text, updated_at::text
        """,
        student["student_id"],
        request.start_date,
        request.end_date,
        request.reason,
        request.reason_category,
    )
    return dict(row)


@router.get("", response_model=list[LeaveResponse])
async def my_leave(db: Connection = Depends(get_db), student: dict = Depends(get_current_student)):
    rows = await db.fetch(
        """
        SELECT id, student_id, start_date, end_date, reason, reason_category, is_approved,
               approved_by, approved_at::text, created_at::text, updated_at::text
        FROM leave_periods
        WHERE student_id = $1
        ORDER BY start_date DESC
        """,
        student["student_id"],
    )
    return [dict(row) for row in rows]


@router.get("/all")
async def all_leave(db: Connection = Depends(get_db), staff: dict = Depends(require_staff)):
    rows = await db.fetch("SELECT * FROM view_student_leave_periods")
    return [dict(row) for row in rows]


@router.put("/{leave_id}/decision", response_model=MessageResponse)
async def decide_leave(leave_id: int, request: LeaveDecisionRequest, db: Connection = Depends(get_db), staff: dict = Depends(require_staff)):
    result = await db.execute(
        """
        UPDATE leave_periods
        SET is_approved = $1, approved_by = $2, approved_at = CURRENT_TIMESTAMP
        WHERE id = $3
        """,
        request.is_approved,
        staff["staff_id"],
        leave_id,
    )
    if result.endswith("0"):
        raise HTTPException(status_code=404, detail="Leave request not found")
    return MessageResponse(message="Leave request updated")
