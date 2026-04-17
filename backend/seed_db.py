import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
from dotenv import load_dotenv
from pathlib import Path
import os
import uuid

ROOT_DIR = Path(__file__).parent
load_dotenv(ROOT_DIR / '.env')

mongo_url = os.environ['MONGO_URL']
client = AsyncIOMotorClient(mongo_url)
db = client[os.environ['DB_NAME']]

async def seed_data():
    print("Starting database seeding...")
    
    # Clear existing data
    await db.tables.delete_many({})
    await db.menu_items.delete_many({})
    await db.orders.delete_many({})
    await db.bills.delete_many({})
    print("Cleared existing data")
    
    # Seed tables
    tables = [
        {
            "id": str(uuid.uuid4()),
            "table_number": "1",
            "capacity": 4,
            "status": "available",
            "created_at": "2026-01-01T00:00:00+00:00"
        },
        {
            "id": str(uuid.uuid4()),
            "table_number": "2",
            "capacity": 2,
            "status": "available",
            "created_at": "2026-01-01T00:00:00+00:00"
        },
        {
            "id": str(uuid.uuid4()),
            "table_number": "3",
            "capacity": 6,
            "status": "available",
            "created_at": "2026-01-01T00:00:00+00:00"
        },
        {
            "id": str(uuid.uuid4()),
            "table_number": "4",
            "capacity": 4,
            "status": "available",
            "created_at": "2026-01-01T00:00:00+00:00"
        },
        {
            "id": str(uuid.uuid4()),
            "table_number": "5",
            "capacity": 8,
            "status": "available",
            "created_at": "2026-01-01T00:00:00+00:00"
        }
    ]
    
    await db.tables.insert_many(tables)
    print(f"Seeded {len(tables)} tables")
    
    # Seed menu items
    menu_items = [
        {
            "id": str(uuid.uuid4()),
            "name": "Seafood Pasta",
            "description": "Fresh pasta with prawns, mussels, and a rich tomato sauce",
            "category": "Main Course",
            "price": 450.00,
            "image": "https://images.unsplash.com/photo-1762922425232-ab2b6b251739?crop=entropy&cs=srgb&fm=jpg&ixid=M3w3NDk1NzZ8MHwxfHNlYXJjaHwxfHxnb3VybWV0JTIwZm9vZCUyMHBsYXRlJTIwdG9wJTIwdmlld3xlbnwwfHx8fDE3NzY0MDMxMDh8MA&ixlib=rb-4.1.0&q=85",
            "available": True,
            "created_at": "2026-01-01T00:00:00+00:00"
        },
        {
            "id": str(uuid.uuid4()),
            "name": "Grilled Chicken Salad",
            "description": "Tender grilled chicken on a bed of mixed greens with vinaigrette",
            "category": "Salad",
            "price": 320.00,
            "image": "https://images.unsplash.com/photo-1761315600943-d8a5bb0c499f?crop=entropy&cs=srgb&fm=jpg&ixid=M3w3NDk1NzZ8MHwxfHNlYXJjaHwyfHxnb3VybWV0JTIwZm9vZCUyMHBsYXRlJTIwdG9wJTIwdmlld3xlbnwwfHx8fDE3NzY0MDMxMDh8MA&ixlib=rb-4.1.0&q=85",
            "available": True,
            "created_at": "2026-01-01T00:00:00+00:00"
        },
        {
            "id": str(uuid.uuid4()),
            "name": "Mushroom Risotto",
            "description": "Creamy Italian rice with wild mushrooms and parmesan",
            "category": "Main Course",
            "price": 380.00,
            "image": "https://images.pexels.com/photos/5865234/pexels-photo-5865234.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=650&w=940",
            "available": True,
            "created_at": "2026-01-01T00:00:00+00:00"
        },
        {
            "id": str(uuid.uuid4()),
            "name": "Tiramisu",
            "description": "Classic Italian dessert with coffee-soaked ladyfingers",
            "category": "Dessert",
            "price": 220.00,
            "image": "https://images.unsplash.com/photo-1712727537456-3fc29b381ba3?crop=entropy&cs=srgb&fm=jpg&ixid=M3w4NjAxODF8MHwxfHNlYXJjaHwyfHxyZXN0YXVyYW50JTIwaW50ZXJpb3IlMjBibHVyfGVufDB8fHx8MTc3NjQwMzEwOHww&ixlib=rb-4.1.0&q=85",
            "available": True,
            "created_at": "2026-01-01T00:00:00+00:00"
        },
        {
            "id": str(uuid.uuid4()),
            "name": "Margherita Pizza",
            "description": "Fresh mozzarella, tomatoes, and basil on thin crust",
            "category": "Main Course",
            "price": 350.00,
            "image": "https://images.unsplash.com/photo-1762922425232-ab2b6b251739?crop=entropy&cs=srgb&fm=jpg&ixid=M3w3NDk1NzZ8MHwxfHNlYXJjaHwxfHxnb3VybWV0JTIwZm9vZCUyMHBsYXRlJTIwdG9wJTIwdmlld3xlbnwwfHx8fDE3NzY0MDMxMDh8MA&ixlib=rb-4.1.0&q=85",
            "available": True,
            "created_at": "2026-01-01T00:00:00+00:00"
        },
        {
            "id": str(uuid.uuid4()),
            "name": "Caesar Salad",
            "description": "Romaine lettuce with Caesar dressing, croutons, and parmesan",
            "category": "Salad",
            "price": 280.00,
            "image": "https://images.unsplash.com/photo-1761315600943-d8a5bb0c499f?crop=entropy&cs=srgb&fm=jpg&ixid=M3w3NDk1NzZ8MHwxfHNlYXJjaHwyfHxnb3VybWV0JTIwZm9vZCUyMHBsYXRlJTIwdG9wJTIwdmlld3xlbnwwfHx8fDE3NzY0MDMxMDh8MA&ixlib=rb-4.1.0&q=85",
            "available": True,
            "created_at": "2026-01-01T00:00:00+00:00"
        },
        {
            "id": str(uuid.uuid4()),
            "name": "Fresh Orange Juice",
            "description": "Freshly squeezed orange juice",
            "category": "Beverage",
            "price": 120.00,
            "image": "https://images.pexels.com/photos/5865234/pexels-photo-5865234.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=650&w=940",
            "available": True,
            "created_at": "2026-01-01T00:00:00+00:00"
        },
        {
            "id": str(uuid.uuid4()),
            "name": "Espresso",
            "description": "Rich Italian espresso",
            "category": "Beverage",
            "price": 80.00,
            "image": "https://images.unsplash.com/photo-1712727537456-3fc29b381ba3?crop=entropy&cs=srgb&fm=jpg&ixid=M3w4NjAxODF8MHwxfHNlYXJjaHwyfHxyZXN0YXVyYW50JTIwaW50ZXJpb3IlMjBibHVyfGVufDB8fHx8MTc3NjQwMzEwOHww&ixlib=rb-4.1.0&q=85",
            "available": True,
            "created_at": "2026-01-01T00:00:00+00:00"
        }
    ]
    
    await db.menu_items.insert_many(menu_items)
    print(f"Seeded {len(menu_items)} menu items")
    
    # Seed owner password (default: owner123)
    import hashlib
    await db.settings.delete_many({})
    await db.settings.insert_one({
        "key": "owner_password",
        "value": hashlib.sha256("owner123".encode()).hexdigest()
    })
    print("Seeded owner password (default: owner123)")
    
    print("Database seeding completed successfully!")
    client.close()

if __name__ == "__main__":
    asyncio.run(seed_data())
