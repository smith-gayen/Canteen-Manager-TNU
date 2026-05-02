from datetime import datetime, timedelta, timezone
from fastapi import APIRouter, Depends, HTTPException, Request, status
from asyncpg import Connection
from app.dependencies import get_current_user, get_db
from app.config import settings
from app.schemas.auth import AuthLogResponse, CurrentUserResponse, RegisterRequest, LoginRequest, SessionResponse, TokenResponse
from app.services.auth_service import hash_password, verify_password, create_access_token, create_refresh_token, hash_token

router = APIRouter(prefix="/api/auth", tags=["auth"])
MAX_LOGIN_ATTEMPTS = 5
LOCK_MINUTES = 15

def _client_ip(request: Request) -> str | None:
    forwarded = request.headers.get("x-forwarded-for")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.client.host if request.client else None

async def _write_auth_log(
    db: Connection,
    *,
    user_id: int | None,
    action: str,
    success: bool,
    request: Request,
    failure_reason: str | None = None,
    session_id: int | None = None,
    token_fingerprint: str | None = None,
):
    await db.execute(
        """
        INSERT INTO auth_logs (
            user_id, action, success, ip_address, device_info, user_agent,
            platform, failure_reason, session_id, token_fingerprint
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
        """,
        user_id,
        action,
        success,
        _client_ip(request),
        request.headers.get("user-agent"),
        request.headers.get("user-agent"),
        request.headers.get("x-client-platform"),
        failure_reason,
        session_id,
        token_fingerprint,
    )

@router.post("/register", status_code=status.HTTP_201_CREATED)
async def register(request: RegisterRequest, db: Connection = Depends(get_db)):
    # 1. Check if email exists
    existing_user = await db.fetchrow("SELECT id FROM users WHERE email = $1", request.email)
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")

    # 2. Check if UID exists
    existing_student = await db.fetchrow("SELECT id FROM students WHERE uid = $1", request.uid)
    if existing_student:
        raise HTTPException(status_code=400, detail="UID already registered")

    # 3. Get role_id for 'student'
    role = await db.fetchrow("SELECT id FROM roles WHERE role_name = 'student'")
    if not role:
        raise HTTPException(status_code=500, detail="Student role not found in database")
    role_id = role["id"]

    # 4. Get hostel_id
    hostel = await db.fetchrow("SELECT id FROM hostels WHERE name = $1", request.hostel)
    if not hostel:
        raise HTTPException(status_code=400, detail="Invalid hostel name")
    hostel_id = hostel["id"]

    # 5. Insert into users and students
    hashed_password = hash_password(request.password)
    
    async with db.transaction():
        user_id = await db.fetchval(
            "INSERT INTO users (role_id, email, password_hash) VALUES ($1, $2, $3) RETURNING id",
            role_id, request.email, hashed_password
        )
        
        await db.execute(
            """
            INSERT INTO students (user_id, first_name, middle_name, last_name, phone, uid, hostel_id, room_number) 
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            """,
            user_id,
            request.first_name,
            request.middle_name,
            request.last_name,
            request.phone,
            request.uid,
            hostel_id,
            request.room,
        )

    return {"message": "User registered successfully"}

@router.post("/login", response_model=TokenResponse)
async def login(payload: LoginRequest, request: Request, db: Connection = Depends(get_db)):
    # Accept email OR UID
    if "@" in payload.identifier:
        # Lookup by email
        user_record = await db.fetchrow(
            """
            SELECT u.id, u.password_hash, u.is_active, u.login_attempts, u.locked_until, r.role_name
            FROM users u
            JOIN roles r ON u.role_id = r.id
            WHERE u.email = $1
            """, 
            payload.identifier
        )
    else:
        # Lookup by UID
        user_record = await db.fetchrow(
            """
            SELECT u.id, u.password_hash, u.is_active, u.login_attempts, u.locked_until, r.role_name
            FROM users u
            JOIN students s ON u.id = s.user_id
            JOIN roles r ON u.role_id = r.id
            WHERE s.uid = $1
            """, 
            payload.identifier
        )

    if not user_record:
        await _write_auth_log(db, user_id=None, action="failed_login", success=False, request=request, failure_reason="user_not_found")
        raise HTTPException(status_code=401, detail="Invalid credentials")

    if not user_record["is_active"]:
        await _write_auth_log(db, user_id=user_record["id"], action="failed_login", success=False, request=request, failure_reason="inactive_account")
        raise HTTPException(status_code=403, detail="Account is disabled")

    locked_until = user_record["locked_until"]
    if locked_until and locked_until > datetime.now():
        await _write_auth_log(db, user_id=user_record["id"], action="failed_login", success=False, request=request, failure_reason="account_locked")
        raise HTTPException(status_code=423, detail="Account is temporarily locked")

    if not verify_password(payload.password, user_record["password_hash"]):
        attempts = min((user_record["login_attempts"] or 0) + 1, 10)
        new_locked_until = None
        action = "failed_login"
        reason = "invalid_password"
        if attempts >= MAX_LOGIN_ATTEMPTS:
            new_locked_until = datetime.now() + timedelta(minutes=LOCK_MINUTES)
            action = "account_locked"
            reason = "too_many_failed_attempts"
        await db.execute(
            "UPDATE users SET login_attempts = $1, locked_until = $2 WHERE id = $3",
            attempts,
            new_locked_until,
            user_record["id"],
        )
        await _write_auth_log(db, user_id=user_record["id"], action=action, success=False, request=request, failure_reason=reason)
        raise HTTPException(status_code=401, detail="Invalid credentials")

    access_token = create_access_token({"sub": str(user_record["id"]), "role": user_record["role_name"]})
    refresh_token = create_refresh_token({"sub": str(user_record["id"])})
    access_hash = hash_token(access_token)
    refresh_hash = hash_token(refresh_token)
    now = datetime.now(timezone.utc).replace(tzinfo=None)
    expires_at = now + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    refresh_expires_at = now + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)

    async with db.transaction():
        await db.execute(
            """
            UPDATE users
            SET login_attempts = 0, locked_until = NULL, last_login_at = CURRENT_TIMESTAMP, last_login_ip = $1
            WHERE id = $2
            """,
            _client_ip(request),
            user_record["id"],
        )
        session_id = await db.fetchval(
            """
            INSERT INTO sessions (
                user_id, access_token_hash, refresh_token_hash, device_info, device_id,
                ip_address, platform, is_mobile, expires_at, refresh_expires_at, last_used_at
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, CURRENT_TIMESTAMP)
            RETURNING id
            """,
            user_record["id"],
            access_hash,
            refresh_hash,
            request.headers.get("user-agent"),
            request.headers.get("x-device-id"),
            _client_ip(request),
            request.headers.get("x-client-platform"),
            request.headers.get("x-client-platform") in ("ios", "android"),
            expires_at,
            refresh_expires_at,
        )
        await _write_auth_log(
            db,
            user_id=user_record["id"],
            action="login",
            success=True,
            request=request,
            session_id=session_id,
            token_fingerprint=access_hash[:16],
        )

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        session_id=session_id,
    )

@router.get("/me", response_model=CurrentUserResponse)
async def me(current_user: dict = Depends(get_current_user), db: Connection = Depends(get_db)):
    student = await db.fetchrow(
        """
        SELECT
            u.id,
            u.email,
            r.role_name AS role,
            s.first_name,
            s.middle_name,
            s.last_name,
            s.phone,
            s.uid,
            h.name AS hostel,
            s.room_number AS room
        FROM users u
        JOIN roles r ON u.role_id = r.id
        LEFT JOIN students s ON s.user_id = u.id
        LEFT JOIN hostels h ON h.id = s.hostel_id
        WHERE u.id = $1
        """,
        current_user["id"],
    )
    if not student:
        raise HTTPException(status_code=404, detail="User profile not found")
    return dict(student)

@router.get("/sessions", response_model=list[SessionResponse])
async def list_sessions(current_user: dict = Depends(get_current_user), db: Connection = Depends(get_db)):
    rows = await db.fetch(
        """
        SELECT id, user_id, device_info, device_id, ip_address, platform, is_mobile,
               created_at::text, expires_at::text, refresh_expires_at::text,
               last_used_at::text, revoked_at::text, logout_at::text, revoked, revoked_reason
        FROM sessions
        WHERE user_id = $1
        ORDER BY created_at DESC
        """,
        current_user["id"],
    )
    return [dict(row) for row in rows]

@router.post("/sessions/{session_id}/revoke")
async def revoke_session(session_id: int, request: Request, current_user: dict = Depends(get_current_user), db: Connection = Depends(get_db)):
    result = await db.execute(
        """
        UPDATE sessions
        SET revoked = TRUE, revoked_at = CURRENT_TIMESTAMP, logout_at = CURRENT_TIMESTAMP, revoked_reason = 'user_revoke'
        WHERE id = $1 AND user_id = $2 AND revoked = FALSE
        """,
        session_id,
        current_user["id"],
    )
    if result.endswith("0"):
        raise HTTPException(status_code=404, detail="Active session not found")
    await _write_auth_log(db, user_id=current_user["id"], action="logout", success=True, request=request, session_id=session_id)
    return {"message": "Session revoked"}

@router.get("/logs", response_model=list[AuthLogResponse])
async def auth_logs(current_user: dict = Depends(get_current_user), db: Connection = Depends(get_db)):
    rows = await db.fetch(
        """
        SELECT id, user_id, action, success, ip_address, device_info, user_agent,
               platform, failure_reason, session_id, timestamp::text
        FROM auth_logs
        WHERE user_id = $1
        ORDER BY timestamp DESC
        LIMIT 100
        """,
        current_user["id"],
    )
    return [dict(row) for row in rows]
