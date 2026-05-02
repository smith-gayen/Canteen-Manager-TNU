from fastapi import FastAPI
from contextlib import asynccontextmanager
from app.database import connect_db, close_db
import traceback
import uuid

from app.routes.auth import router as auth_router
from app.routes.meals import router as meals_router
from app.routes.bookings import router as bookings_router
from app.routes.tokens import router as tokens_router
from app.routes.leave import router as leave_router
from app.routes.feedback import router as feedback_router
from app.routes.notifications import router as notifications_router
from app.routes.settings import router as settings_router
from app.routes.reports import router as reports_router
from app.routes.admin import router as admin_router
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app import database

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup event: Connect to database
    await connect_db()
    yield
    # Shutdown event: Close database connection
    await close_db()

app = FastAPI(title="Canteen Backend API", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.middleware("http")
async def error_log_middleware(request, call_next):
    request_id = request.headers.get("x-request-id", str(uuid.uuid4()))
    try:
        response = await call_next(request)
        response.headers["x-request-id"] = request_id
        return response
    except Exception as exc:
        if database.pool is not None:
            try:
                async with database.pool.acquire() as conn:
                    await conn.execute(
                        """
                        INSERT INTO error_logs (
                            severity, error_code, request_id, endpoint, http_method,
                            status_code, message, stack_trace, exception_type, environment
                        )
                        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
                        """,
                        "error",
                        exc.__class__.__name__,
                        request_id,
                        str(request.url.path),
                        request.method,
                        500,
                        str(exc),
                        traceback.format_exc(),
                        exc.__class__.__name__,
                        getattr(settings, "APP_ENV", "development"),
                    )
            except Exception:
                pass
        raise

app.include_router(auth_router)
app.include_router(meals_router)
app.include_router(bookings_router)
app.include_router(tokens_router)
app.include_router(leave_router)
app.include_router(feedback_router)
app.include_router(notifications_router)
app.include_router(settings_router)
app.include_router(reports_router)
app.include_router(admin_router)

@app.get("/")
async def root():
    return {"message": "API running"}
