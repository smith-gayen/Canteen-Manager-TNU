import asyncio

from app import database
from app.database import close_db, connect_db


async def main():
    await connect_db()
    try:
        async with database.pool.acquire() as conn:
            version = await conn.fetchval("SELECT version()")
            current_db = await conn.fetchval("SELECT current_database()")
            tables = await conn.fetch(
                """
                SELECT tablename
                FROM pg_tables
                WHERE schemaname = 'public'
                ORDER BY tablename
                """
            )
            counts = {}
            for table in [
                "roles",
                "hostels",
                "meal_slots",
                "menu_items",
                "booking_status",
                "users",
                "students",
                "bookings",
            ]:
                counts[table] = await conn.fetchval(f"SELECT count(*) FROM {table}")

            print(f"database={current_db}")
            print(f"server={version.split(',')[0]}")
            print(f"table_count={len(tables)}")
            print("tables=" + ",".join(row["tablename"] for row in tables))
            print("counts=" + ",".join(f"{key}:{value}" for key, value in counts.items()))
    finally:
        await close_db()


if __name__ == "__main__":
    asyncio.run(main())
