from datetime import date
from fastapi import APIRouter, Depends
from asyncpg import Connection

from app.dependencies import get_db, require_staff

router = APIRouter(prefix="/api/reports", tags=["reports"])


@router.get("/today/bookings")
async def todays_bookings(db: Connection = Depends(get_db), staff: dict = Depends(require_staff)):
    rows = await db.fetch("SELECT * FROM view_todays_bookings ORDER BY meal_slot, hostel, student_name")
    return [dict(row) for row in rows]


@router.get("/today/meal-count")
async def meal_count_today(db: Connection = Depends(get_db), staff: dict = Depends(require_staff)):
    rows = await db.fetch("SELECT * FROM view_meal_count_today")
    return [dict(row) for row in rows]


@router.get("/active-tokens")
async def active_tokens(db: Connection = Depends(get_db), staff: dict = Depends(require_staff)):
    rows = await db.fetch("SELECT * FROM view_active_tokens ORDER BY meal_slot, student_name")
    return [dict(row) for row in rows]


@router.get("/student-history")
async def student_history(uid: str | None = None, from_date: date | None = None, to_date: date | None = None, db: Connection = Depends(get_db), staff: dict = Depends(require_staff)):
    query = "SELECT * FROM view_student_booking_history WHERE 1=1"
    params = []
    if uid:
        params.append(uid)
        query += f" AND student_uid = ${len(params)}"
    if from_date:
        params.append(from_date)
        query += f" AND date >= ${len(params)}"
    if to_date:
        params.append(to_date)
        query += f" AND date <= ${len(params)}"
    query += " ORDER BY date DESC, meal_slot"
    rows = await db.fetch(query, *params)
    return [dict(row) for row in rows]
