from fastapi import APIRouter, Depends, HTTPException
from asyncpg import Connection
from datetime import date, datetime
from typing import List
from app.dependencies import get_db, get_current_student, get_current_user, require_staff
from app.schemas.meals import MealSlotResp, MealMenuResp, TodayResp, MenuItemCreateRequest, MealMenuCreateRequest

router = APIRouter(prefix="/api/meals", tags=["meals"])

@router.get("/slots", response_model=List[MealSlotResp])
async def get_slots(db: Connection = Depends(get_db), current_user: dict = Depends(get_current_user)):
    slots = await db.fetch("SELECT * FROM meal_slots WHERE is_active = TRUE ORDER BY display_order")
    return [dict(s) for s in slots]

@router.get("/menu", response_model=MealMenuResp)
async def get_menu(date: date, slot_id: int, db: Connection = Depends(get_db), student: dict = Depends(get_current_student)):
    from app.services.booking_service import find_or_create_meal_menu
    
    hostel_id = student["hostel_id"]
    if not hostel_id:
        raise HTTPException(status_code=400, detail="Student is not assigned to any hostel")
        
    menu_id = await find_or_create_meal_menu(db, hostel_id, slot_id, date)
    
    query = """
        SELECT
            mi.id,
            mi.name,
            mi.description,
            (mi.type = 'veg') AS is_veg,
            mmi.exclusive_group
        FROM menu_items mi
        JOIN meal_menu_items mmi ON mi.id = mmi.menu_item_id
        WHERE mmi.meal_menu_id = $1 AND mi.is_active = TRUE
        ORDER BY mmi.sort_order, mi.name
    """
    items = await db.fetch(query, menu_id)
    
    return {
        "id": menu_id,
        "slot_id": slot_id,
        "date": date,
        "items": [dict(i) for i in items]
    }

@router.get("/today", response_model=TodayResp)
async def get_today(db: Connection = Depends(get_db), current_user: dict = Depends(get_current_user)):
    now = datetime.now()
    current_time = now.time()
    
    slots = await db.fetch("SELECT * FROM meal_slots WHERE is_active = TRUE ORDER BY start_time")
    
    current_phase = "Unknown"
    next_meal = "Unknown"
    cutoff = None
    
    for slot in slots:
        if slot['start_time'] <= current_time <= slot['end_time']:
            current_phase = slot['name']
            cutoff = slot['booking_cutoff_time']
            break
            
    if current_phase == "Unknown":
        for slot in slots:
            if current_time < slot['start_time']:
                next_meal = slot['name']
                cutoff = slot['booking_cutoff_time']
                break
                
    if not cutoff and slots:
        cutoff = slots[0]['booking_cutoff_time']
            
    if cutoff:
        cutoff_dt = datetime.combine(now.date(), cutoff)
        if cutoff_dt < now:
            cutoff_dt = cutoff_dt.replace(day=cutoff_dt.day)
        remaining = max(cutoff_dt - now, datetime.min - datetime.min)
        countdown_hours = int(remaining.total_seconds() // 3600)
        countdown_minutes = int((remaining.total_seconds() % 3600) // 60)
    else:
        countdown_hours = 0
        countdown_minutes = 0

    return {
        "current_phase": current_phase,
        "next_meal": next_meal,
        "cutoff_time": cutoff or current_time,
        "countdown_hours": countdown_hours,
        "countdown_minutes": countdown_minutes
    }

@router.get("/items")
async def list_menu_items(db: Connection = Depends(get_db), current_user: dict = Depends(get_current_user)):
    rows = await db.fetch("SELECT * FROM menu_items ORDER BY name")
    return [dict(row) for row in rows]

@router.post("/items")
async def create_menu_item(request: MenuItemCreateRequest, db: Connection = Depends(get_db), staff: dict = Depends(require_staff)):
    row = await db.fetchrow(
        """
        INSERT INTO menu_items (
            name, type, description, short_description, allergens, spice_level,
            default_quantity, unit, base_price, is_premium, created_by
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
        RETURNING *
        """,
        request.name,
        request.type,
        request.description,
        request.short_description,
        request.allergens,
        request.spice_level,
        request.default_quantity,
        request.unit,
        request.base_price,
        request.is_premium,
        staff["id"],
    )
    return dict(row)

@router.post("/menus")
async def create_meal_menu(request: MealMenuCreateRequest, db: Connection = Depends(get_db), staff: dict = Depends(require_staff)):
    async with db.transaction():
        menu_id = await db.fetchval(
            """
            INSERT INTO meal_menus (
                hostel_id, meal_slot_id, date, day_of_week, is_recurring,
                is_published, max_bookings, special_notes, created_by, updated_by
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $9)
            RETURNING id
            """,
            request.hostel_id,
            request.meal_slot_id,
            request.date,
            request.day_of_week,
            request.is_recurring,
            request.is_published,
            request.max_bookings,
            request.special_notes,
            staff["id"],
        )
        for item in request.items:
            await db.execute(
                """
                INSERT INTO meal_menu_items (
                    meal_menu_id, menu_item_id, quantity, quantity_value, unit, is_default,
                    is_optional, max_selectable, price_override, sort_order, exclusive_group
                )
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
                """,
                menu_id,
                item.menu_item_id,
                item.quantity,
                item.quantity_value,
                item.unit,
                item.is_default,
                item.is_optional,
                item.max_selectable,
                item.price_override,
                item.sort_order,
                item.exclusive_group,
            )
    return {"id": menu_id, "message": "Meal menu created"}

@router.put("/menus/{menu_id}/publish")
async def publish_menu(menu_id: int, is_published: bool = True, db: Connection = Depends(get_db), staff: dict = Depends(require_staff)):
    result = await db.execute(
        "UPDATE meal_menus SET is_published = $1, updated_by = $2 WHERE id = $3",
        is_published,
        staff["id"],
        menu_id,
    )
    if result.endswith("0"):
        raise HTTPException(status_code=404, detail="Meal menu not found")
    return {"message": "Meal menu updated"}
