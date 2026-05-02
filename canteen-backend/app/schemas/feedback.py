from pydantic import BaseModel, Field


class FeedbackCreateRequest(BaseModel):
    booking_id: int | None = None
    food_rating: int = Field(..., ge=1, le=5)
    service_rating: int = Field(..., ge=1, le=5)
    cleanliness_rating: int = Field(..., ge=1, le=5)
    comment: str | None = None
    images: list[str] = []
    is_anonymous: bool = False
    tag_ids: list[int] = []


class FeedbackResolveRequest(BaseModel):
    resolution_notes: str = Field(..., min_length=2)


class FeedbackResponse(BaseModel):
    id: int
    student_id: int
    booking_id: int | None = None
    food_rating: int | None = None
    service_rating: int | None = None
    cleanliness_rating: int | None = None
    comment: str | None = None
    images: list[str] | None = None
    is_anonymous: bool
    is_locked: bool
    is_resolved: bool
    resolution_notes: str | None = None
    created_at: str | None = None
    updated_at: str | None = None
