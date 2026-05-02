import asyncio
import asyncpg
import os

async def setup():
    try:
        db_host = os.getenv('DB_HOST', 'localhost')
        db_port = int(os.getenv('DB_PORT', '5432'))
        db_user = os.getenv('DB_USER', 'postgres')
        db_password = os.getenv('DB_PASSWORD', 'postgres')
        db_name = os.getenv('DB_NAME', 'canteen_db')

        # Connect to default postgres DB
        print("Connecting to postgres...")
        conn = await asyncpg.connect(
            user=db_user,
            password=db_password,
            database='postgres',
            host=db_host,
            port=db_port,
        )
        
        # Check if canteen_db exists
        exists = await conn.fetchval("SELECT 1 FROM pg_database WHERE datname = $1", db_name)
        if not exists:
            # Create database
            await conn.execute(f'CREATE DATABASE "{db_name}"')
            print(f'Database {db_name} created.')
        else:
            print(f'Database {db_name} already exists.')
        await conn.close()

        # Now connect to canteen_db and run schema.sql
        print(f"Connecting to {db_name}...")
        conn = await asyncpg.connect(
            user=db_user,
            password=db_password,
            database=db_name,
            host=db_host,
            port=db_port,
        )
        with open('schema.sql', 'r', encoding='utf-8') as f:
            schema = f.read()
        await conn.execute(schema)
        print('schema.sql executed successfully. Database is fully initialized!')
        await conn.close()

    except Exception as e:
        print('Error:', e)

asyncio.run(setup())
