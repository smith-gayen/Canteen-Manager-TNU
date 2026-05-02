from fastapi import APIRouter, Depends, HTTPException
from asyncpg import Connection

from app.dependencies import get_current_student, get_db, require_staff
from app.schemas.common import MessageResponse
from app.schemas.feedback import FeedbackCreateRequest, FeedbackResolveRequest, FeedbackResponse

router = APIRouter(prefix="/api/feedback", tags=["feedback"])


@router.post("", response_model=FeedbackResponse)
async def create_feedback(request: FeedbackCreateRequest, db: Connection = Depends(get_db), student: dict = Depends(get_current_student)):
    if request.booking_id:
        owner = await db.fetchval("SELECT student_id FROM bookings WHERE id = $1", request.booking_id)
        if owner != student["student_id"]:
            raise HTTPException(status_code=403, detail="Booking does not belong to this student")

    async with db.transaction():
        row = await db.fetchrow(
            """
            INSERT INTO feedback (
                student_id, booking_id, food_rating, service_rating, cleanliness_rating,
                comment, images, is_anonymous, is_locked, unlocked_at
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, FALSE, CURRENT_TIMESTAMP)
            RETURNING id, student_id, booking_id, food_rating, service_rating, cleanliness_rating,
                      comment, images, is_anonymous, is_locked, is_resolved, resolution_notes,
                      created_at::text, updated_at::text
            """,
            student["student_id"],
            request.booking_id,
            request.food_rating,
            request.service_rating,
            request.cleanliness_rating,
            request.comment,
            request.images,
            request.is_anonymous,
        )
        for tag_id in request.tag_ids:
            await db.execute(
                "INSERT INTO feedback_tag_links (feedback_id, tag_id) VALUES ($1, $2) ON CONFLICT DO NOTHING",
                row["id"],
                tag_id,
            )
    return dict(row)


@router.get("/mine", response_model=list[FeedbackResponse])
async def my_feedback(db: Connection = Depends(get_db), student: dict = Depends(get_current_student)):
    rows = await db.fetch(
        """
        SELECT id, student_id, booking_id, food_rating, service_rating, cleanliness_rating,
               comment, images, is_anonymous, is_locked, is_resolved, resolution_notes,
               created_at::text, updated_at::text
        FROM feedback
        WHERE student_id = $1
        ORDER BY created_at DESC
        """,
        student["student_id"],
    )
    return [dict(row) for row in rows]


@router.get("/tags")
async def tags(db: Connection = Depends(get_db)):
    rows = await db.fetch("SELECT * FROM feedback_tags WHERE is_active = TRUE ORDER BY sort_order, display_label")
    return [dict(row) for row in rows]


@router.get("/all")
async def all_feedback(db: Connection = Depends(get_db), staff: dict = Depends(require_staff)):
    rows = await db.fetch(
        """
        SELECT f.*, s.uid, s.first_name, s.last_name
        FROM feedback f
        JOIN students s ON s.id = f.student_id
        ORDER BY f.created_at DESC
        """
    )
    return [dict(row) for row in rows]


@router.put("/{feedback_id}/resolve", response_model=MessageResponse)
async def resolve_feedback(feedback_id: int, request: FeedbackResolveRequest, db: Connection = Depends(get_db), staff: dict = Depends(require_staff)):
    result = await db.execute(
        """
        UPDATE feedback
        SET is_resolved = TRUE, resolved_by = $1, resolved_at = CURRENT_TIMESTAMP, resolution_notes = $2
        WHERE id = $3
        """,
        staff["staff_id"],
        request.resolution_notes,
        feedback_id,
    )
    if result.endswith("0"):
        raise HTTPException(status_code=404, detail="Feedback not found")
    return MessageResponse(message="Feedback resolved")
