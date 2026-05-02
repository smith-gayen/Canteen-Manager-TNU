from fastapi import APIRouter, Depends, HTTPException, status
from asyncpg import Connection

from app.dependencies import get_db, require_role, require_staff
from app.schemas.admin import StaffCreateRequest, StaffResponse, StaffUpdateRequest
from app.schemas.common import MessageResponse
from app.services.auth_service import hash_password

router = APIRouter(prefix="/api/admin", tags=["admin"])


@router.get("/users")
async def list_users(db: Connection = Depends(get_db), admin: dict = Depends(require_role(["admin", "warden"]))):
    rows = await db.fetch(
        """
        SELECT u.id, u.email, u.email_verified, u.is_active, u.login_attempts, u.locked_until,
               u.last_login_at, u.last_login_ip, u.created_at, r.role_name
        FROM users u
        JOIN roles r ON r.id = u.role_id
        ORDER BY u.id
        """
    )
    return [dict(row) for row in rows]


@router.get("/staff", response_model=list[StaffResponse])
async def list_staff(db: Connection = Depends(get_db), staff: dict = Depends(require_staff)):
    rows = await db.fetch(
        """
        SELECT st.id, st.user_id, u.email, st.first_name, st.last_name, st.phone, st.designation,
               st.hostel_id, st.can_scan_qr, st.can_edit_menu, st.can_view_reports,
               st.can_manage_staff, st.is_active
        FROM staff st
        JOIN users u ON u.id = st.user_id
        ORDER BY st.id
        """
    )
    return [dict(row) for row in rows]


@router.post("/staff", response_model=StaffResponse, status_code=status.HTTP_201_CREATED)
async def create_staff(request: StaffCreateRequest, db: Connection = Depends(get_db), admin: dict = Depends(require_role(["admin"]))):
    role = await db.fetchrow("SELECT id FROM roles WHERE role_name = $1", "canteen_staff")
    if not role:
        raise HTTPException(status_code=500, detail="canteen_staff role missing")
    existing = await db.fetchval("SELECT id FROM users WHERE email = $1", request.email)
    if existing:
        raise HTTPException(status_code=400, detail="Email already exists")

    async with db.transaction():
        user_id = await db.fetchval(
            """
            INSERT INTO users (role_id, email, email_verified, password_hash)
            VALUES ($1, $2, TRUE, $3)
            RETURNING id
            """,
            role["id"],
            request.email,
            hash_password(request.password),
        )
        staff_id = await db.fetchval(
            """
            INSERT INTO staff (
                user_id, first_name, last_name, phone, designation, hostel_id,
                can_scan_qr, can_edit_menu, can_view_reports, can_manage_staff,
                shift_start, shift_end
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
            RETURNING id
            """,
            user_id,
            request.first_name,
            request.last_name,
            request.phone,
            request.designation,
            request.hostel_id,
            request.can_scan_qr,
            request.can_edit_menu,
            request.can_view_reports,
            request.can_manage_staff,
            request.shift_start,
            request.shift_end,
        )
    row = await _staff_by_id(db, staff_id)
    return dict(row)


@router.put("/staff/{staff_id}", response_model=StaffResponse)
async def update_staff(staff_id: int, request: StaffUpdateRequest, db: Connection = Depends(get_db), admin: dict = Depends(require_role(["admin"]))):
    current = await db.fetchrow("SELECT * FROM staff WHERE id = $1", staff_id)
    if not current:
        raise HTTPException(status_code=404, detail="Staff not found")
    data = request.model_dump(exclude_unset=True)
    values = {
        "phone": data.get("phone", current["phone"]),
        "designation": data.get("designation", current["designation"]),
        "hostel_id": data.get("hostel_id", current["hostel_id"]),
        "can_scan_qr": data.get("can_scan_qr", current["can_scan_qr"]),
        "can_edit_menu": data.get("can_edit_menu", current["can_edit_menu"]),
        "can_view_reports": data.get("can_view_reports", current["can_view_reports"]),
        "can_manage_staff": data.get("can_manage_staff", current["can_manage_staff"]),
        "shift_start": data.get("shift_start", current["shift_start"]),
        "shift_end": data.get("shift_end", current["shift_end"]),
        "is_active": data.get("is_active", current["is_active"]),
    }
    await db.execute(
        """
        UPDATE staff
        SET phone = $1, designation = $2, hostel_id = $3, can_scan_qr = $4,
            can_edit_menu = $5, can_view_reports = $6, can_manage_staff = $7,
            shift_start = $8, shift_end = $9, is_active = $10
        WHERE id = $11
        """,
        *values.values(),
        staff_id,
    )
    row = await _staff_by_id(db, staff_id)
    return dict(row)


@router.put("/users/{user_id}/active", response_model=MessageResponse)
async def set_user_active(user_id: int, is_active: bool, db: Connection = Depends(get_db), admin: dict = Depends(require_role(["admin"]))):
    result = await db.execute("UPDATE users SET is_active = $1 WHERE id = $2", is_active, user_id)
    if result.endswith("0"):
        raise HTTPException(status_code=404, detail="User not found")
    return MessageResponse(message="User status updated")


async def _staff_by_id(db: Connection, staff_id: int):
    row = await db.fetchrow(
        """
        SELECT st.id, st.user_id, u.email, st.first_name, st.last_name, st.phone, st.designation,
               st.hostel_id, st.can_scan_qr, st.can_edit_menu, st.can_view_reports,
               st.can_manage_staff, st.is_active
        FROM staff st
        JOIN users u ON u.id = st.user_id
        WHERE st.id = $1
        """,
        staff_id,
    )
    if not row:
        raise HTTPException(status_code=404, detail="Staff not found")
    return row
