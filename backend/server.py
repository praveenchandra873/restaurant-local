from fastapi import FastAPI, APIRouter, HTTPException
from dotenv import load_dotenv
from starlette.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient
import os
import logging
import hashlib
from pathlib import Path
from pydantic import BaseModel, Field, ConfigDict
from typing import List, Optional
import uuid
from datetime import datetime, timezone
from enum import Enum

ROOT_DIR = Path(__file__).parent
load_dotenv(ROOT_DIR / '.env')

mongo_url = os.environ['MONGO_URL']
client = AsyncIOMotorClient(mongo_url)
db = client[os.environ['DB_NAME']]

app = FastAPI()
api_router = APIRouter(prefix="/api")

class TableStatus(str, Enum):
    available = "available"
    occupied = "occupied"

class OrderStatus(str, Enum):
    pending = "pending"
    preparing = "preparing"
    ready = "ready"
    completed = "completed"
    cancelled = "cancelled"

class PaymentStatus(str, Enum):
    pending = "pending"
    paid = "paid"
    cancelled = "cancelled"

class Table(BaseModel):
    model_config = ConfigDict(extra="ignore")
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    table_number: str
    capacity: int
    status: TableStatus = TableStatus.available
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

class TableCreate(BaseModel):
    table_number: str
    capacity: int

class TableUpdate(BaseModel):
    status: Optional[TableStatus] = None
    capacity: Optional[int] = None

class MenuItem(BaseModel):
    model_config = ConfigDict(extra="ignore")
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    name: str
    description: str
    category: str
    price: float
    image: str
    available: bool = True
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

class MenuItemCreate(BaseModel):
    name: str
    description: str
    category: str
    price: float
    image: str
    available: bool = True

class MenuItemUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    category: Optional[str] = None
    price: Optional[float] = None
    image: Optional[str] = None
    available: Optional[bool] = None

class OrderItem(BaseModel):
    menu_item_id: str
    name: str
    quantity: int
    price: float

class Order(BaseModel):
    model_config = ConfigDict(extra="ignore")
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    table_id: str
    table_number: str
    items: List[OrderItem]
    status: OrderStatus = OrderStatus.pending
    notes: str = ""
    total_amount: float
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    updated_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

class OrderCreate(BaseModel):
    table_id: str
    table_number: str
    items: List[OrderItem]
    notes: str = ""

class OrderStatusUpdate(BaseModel):
    status: OrderStatus

class Bill(BaseModel):
    model_config = ConfigDict(extra="ignore")
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    order_id: str
    table_id: str
    table_number: str
    items: List[OrderItem]
    subtotal: float
    tax: float
    total: float
    payment_status: PaymentStatus = PaymentStatus.pending
    payment_method: str = ""
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

class BillCreate(BaseModel):
    order_id: str
    payment_method: str = ""

class BillPaymentUpdate(BaseModel):
    payment_status: PaymentStatus
    payment_method: str

@api_router.get("/")
async def root():
    return {"message": "Restaurant POS API"}

@api_router.post("/reseed")
async def reseed_database():
    """Re-seed the database with fresh data including all 90 Nanhe Cafe menu items."""
    import hashlib as _hashlib

    # Clear all data
    await db.tables.delete_many({})
    await db.menu_items.delete_many({})
    await db.orders.delete_many({})
    await db.bills.delete_many({})
    await db.settings.delete_many({})

    # Seed tables
    tables = []
    for num, cap in [("1",4),("2",2),("3",6),("4",4),("5",8)]:
        tables.append({"id":str(uuid.uuid4()),"table_number":num,"capacity":cap,"status":"available","created_at":"2026-01-01T00:00:00+00:00"})
    await db.tables.insert_many(tables)

    # Seed all 90 menu items
    IMAGES = {
        "Starter": "https://images.unsplash.com/photo-1585410304004-56ae05651552?crop=entropy&cs=srgb&fm=jpg&ixid=M3w3NTY2Nzd8MHwxfHNlYXJjaHwxfHxmcmVuY2glMjBmcmllc3xlbnwwfHx8fDE3NzczMDg1NDF8MA&ixlib=rb-4.1.0&q=85",
        "Maggi": "https://images.unsplash.com/photo-1692273212247-f5efb3fc9b87?crop=entropy&cs=srgb&fm=jpg&ixid=M3w3NTY2Nzd8MHwxfHNlYXJjaHwyfHxtYWdnaXxlbnwwfHx8fDE3NzczMDg1NDF8MA&ixlib=rb-4.1.0&q=85",
        "Sandwich": "https://images.pexels.com/photos/36479818/pexels-photo-36479818.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=650&w=940",
        "Pasta": "https://images.unsplash.com/photo-1762922425232-ab2b6b251739?crop=entropy&cs=srgb&fm=jpg&ixid=M3w3NDk1NzZ8MHwxfHNlYXJjaHwxfHxnb3VybWV0JTIwZm9vZCUyMHBsYXRlJTIwdG9wJTIwdmlld3xlbnwwfHx8fDE3NzY0MDMxMDh8MA&ixlib=rb-4.1.0&q=85",
        "Rice": "https://images.pexels.com/photos/13294535/pexels-photo-13294535.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=650&w=940",
        "Chinese": "https://images.pexels.com/photos/9738993/pexels-photo-9738993.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=650&w=940",
        "Mocktail": "https://images.unsplash.com/photo-1712727537456-3fc29b381ba3?crop=entropy&cs=srgb&fm=jpg&ixid=M3w4NjAxODF8MHwxfHNlYXJjaHwyfHxyZXN0YXVyYW50JTIwaW50ZXJpb3IlMjBibHVyfGVufDB8fHx8MTc3NjQwMzEwOHww&ixlib=rb-4.1.0&q=85",
        "Cold Coffee": "https://images.pexels.com/photos/5865234/pexels-photo-5865234.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=650&w=940",
        "Combo": "https://images.pexels.com/photos/36575097/pexels-photo-36575097.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=650&w=940",
    }
    ALL_ITEMS = [
        ("French Fries","Classic salted french fries","Starter",90),("French Fries (Peri Peri)","Spicy peri peri seasoned fries","Starter",100),("French Fries (Cheese)","Fries topped with melted cheese","Starter",110),("Hot N Sour Soup","Tangy and spicy vegetable soup","Starter",90),("Manchow Soup","Crispy noodle topped Chinese soup","Starter",90),
        ("Plain Maggi","Classic Maggi noodles","Maggi",60),("Plain Maggi Double Masala","Extra spicy Maggi","Maggi",70),("Plain Cheese Maggi","Maggi with melted cheese","Maggi",70),("Vegetable Maggi","Maggi with mixed vegetables","Maggi",80),("Vegetable Cheese Maggi","Veggie Maggi with cheese","Maggi",90),("Cheese Corn Maggi","Maggi with cheese and sweet corn","Maggi",90),("Corn Butter Maggi","Butter corn flavored Maggi","Maggi",90),("Schezwan Maggi","Spicy Schezwan style Maggi","Maggi",90),("Cheese Chilly Maggi","Chilly cheese Maggi","Maggi",90),("Veg Peri Peri Maggi","Peri peri spiced vegetable Maggi","Maggi",90),("Veg Paneer Maggi","Maggi with paneer chunks","Maggi",100),
        ("Bombay Sandwich","Classic Mumbai style sandwich","Sandwich",70),("Veg Sandwich","Mixed vegetable sandwich","Sandwich",70),("Bombay Cheese Sandwich","Bombay sandwich with extra cheese","Sandwich",80),("Veg Cheese Sandwich","Veggie sandwich with cheese","Sandwich",80),("Cheese Corn Sandwich","Corn and cheese grilled sandwich","Sandwich",80),("Cheese Chilly Corn Sandwich","Spicy corn cheese sandwich","Sandwich",90),("Cheese Garlic Sandwich","Garlic butter cheese sandwich","Sandwich",90),("Peri Peri Cheese Corn Sandwich","Peri peri corn cheese sandwich","Sandwich",90),("Paneer Peri Peri Sandwich","Paneer with peri peri spice","Sandwich",100),("Paneer Cheese Sandwich","Paneer and cheese grilled sandwich","Sandwich",100),("Paneer Makhani Sandwich","Paneer makhani filling sandwich","Sandwich",100),("Chocolate Sandwich","Sweet chocolate filled sandwich","Sandwich",100),("Cheese Chocolate Sandwich","Chocolate and cheese combo","Sandwich",110),
        ("Indian Pasta","Desi masala style pasta","Pasta",130),("Red Sauce Pasta","Classic tomato red sauce pasta","Pasta",140),("White Pasta","Creamy white sauce pasta","Pasta",150),("Makhan Sauce Pasta","Butter makhani sauce pasta","Pasta",160),("Red & White Sauce Pasta","Mixed sauce pasta","Pasta",160),
        ("Veg Fried Rice","Classic vegetable fried rice","Rice",170),("Veg Peri-Peri Fried Rice","Spicy peri peri fried rice","Rice",180),("Schezwan Rice","Spicy Schezwan fried rice","Rice",180),("Veg Paneer Rice","Fried rice with paneer","Rice",200),("Paneer-65 Rice","Fried rice with paneer 65","Rice",210),("Mongolian Rice","Indo-Chinese Mongolian rice","Rice",230),("Veg Biryani","Aromatic vegetable biryani","Rice",230),
        ("Veg Chowmein/Noodles","Classic vegetable noodles","Chinese",140),("Hakka Noodles","Indo-Chinese hakka noodles","Chinese",160),("Chilly Garlic Noodles","Spicy garlic flavored noodles","Chinese",160),("Schezwan Noodles","Hot Schezwan sauce noodles","Chinese",160),("Crispy Corn","Golden fried crispy corn kernels","Chinese",180),("Chana Chilly","Spicy chilli chickpeas","Chinese",180),("Chana Roast","Roasted spicy chickpeas","Chinese",180),("Veg Manchurian","Vegetable manchurian in gravy","Chinese",160),("Crispy Corn Chilly","Spicy crispy corn","Chinese",190),("Baby Corn Chilly","Chilli baby corn stir fry","Chinese",190),("Gobi Chilly","Spicy cauliflower chilli","Chinese",190),("Paneer Chilly","Indo-Chinese paneer chilli","Chinese",190),("Mushroom Chilly","Spicy mushroom stir fry","Chinese",200),("Paneer 65","Crispy spiced paneer","Chinese",210),
        ("Virgin Mojito","Classic lime and mint mojito","Mocktail",80),("Blue Lagoon Mojito","Blue curacao flavored mojito","Mocktail",80),("Green Apple Mojito","Refreshing green apple mojito","Mocktail",80),("Kiwi Mojito","Fresh kiwi flavored mojito","Mocktail",80),("Mango Mojito","Sweet mango mojito","Mocktail",80),("Water Melon Mojito","Refreshing watermelon mojito","Mocktail",90),("Long Ice Tea","Classic long island iced tea","Mocktail",90),("Peach Ice Tea","Peach flavored iced tea","Mocktail",90),
        ("Cold Coffee (Regular)","Classic cold coffee","Cold Coffee",90),("Cold Coffee with Ice Cream","Cold coffee with a scoop of ice cream","Cold Coffee",110),("Oreo Milkshake","Creamy Oreo cookie milkshake","Cold Coffee",110),("Chocolate Milkshake","Rich chocolate milkshake","Cold Coffee",110),("Strawberry Milkshake","Fresh strawberry milkshake","Cold Coffee",110),("Mango Milkshake","Sweet mango milkshake","Cold Coffee",110),("Kiwi Milkshake","Kiwi flavored milkshake","Cold Coffee",110),("Pineapple Shake","Tropical pineapple shake","Cold Coffee",110),("Green Apple Milkshake","Tangy green apple milkshake","Cold Coffee",110),("Butterscotch Milkshake","Butterscotch flavored milkshake","Cold Coffee",110),("Kitkat Milkshake","Kitkat chocolate milkshake","Cold Coffee",110),("Black Currant Milkshake","Black currant milkshake","Cold Coffee",110),("Blueberry Milkshake","Blueberry flavored milkshake","Cold Coffee",110),("Vanilla Milkshake","Classic vanilla milkshake","Cold Coffee",110),("Bubble Gum Milkshake","Fun bubblegum milkshake","Cold Coffee",110),("Kitkat Cold Coffee","Cold coffee with Kitkat","Cold Coffee",110),("Cold Coffee without Ice","Cold coffee served without ice","Cold Coffee",110),
        ("Sandwich + Cold Coffee","Any sandwich with cold coffee","Combo",160),("Maggi + Cold Coffee","Any Maggi with cold coffee","Combo",170),("Veg Chowmien + Mojito","Chowmein with any mojito","Combo",210),("Veg Chowmien + Cold Coffee","Chowmein with cold coffee","Combo",220),("Veg Manchurian + Veg Fried Rice","Manchurian with fried rice","Combo",280),("Veg Chowmien + Manchurian","Noodles with manchurian","Combo",300),("Paneer Chilly + Veg Fried Rice","Paneer chilly with fried rice","Combo",300),("Paneer Chilly + Manchurian","Paneer chilly with manchurian","Combo",330),("Veg Chowmien + Paneer Chilly","Noodles with paneer chilly","Combo",330),("Paneer Chilly + Schezwan Rice","Paneer chilly with schezwan rice","Combo",330),
    ]
    menu_docs = []
    for name, desc, cat, price in ALL_ITEMS:
        menu_docs.append({"id":str(uuid.uuid4()),"name":name,"description":desc,"category":cat,"price":float(price),"image":IMAGES.get(cat,IMAGES["Starter"]),"available":True,"created_at":"2026-01-01T00:00:00+00:00"})
    await db.menu_items.insert_many(menu_docs)

    # Seed owner password
    await db.settings.insert_one({"key":"owner_password","value":_hashlib.sha256("owner123".encode()).hexdigest()})

    return {"message": f"Database re-seeded: {len(tables)} tables, {len(menu_docs)} menu items"}

@api_router.get("/tables", response_model=List[Table])
async def get_tables():
    tables = await db.tables.find({}, {"_id": 0}).to_list(1000)
    for table in tables:
        if isinstance(table.get('created_at'), str):
            table['created_at'] = datetime.fromisoformat(table['created_at'])
    return tables

@api_router.post("/tables", response_model=Table)
async def create_table(input: TableCreate):
    table_obj = Table(**input.model_dump())
    doc = table_obj.model_dump()
    doc['created_at'] = doc['created_at'].isoformat()
    await db.tables.insert_one(doc)
    return table_obj

@api_router.put("/tables/{table_id}", response_model=Table)
async def update_table(table_id: str, input: TableUpdate):
    update_data = {k: v for k, v in input.model_dump().items() if v is not None}
    if not update_data:
        raise HTTPException(status_code=400, detail="No fields to update")
    
    result = await db.tables.find_one_and_update(
        {"id": table_id},
        {"$set": update_data},
        return_document=True
    )
    
    if not result:
        raise HTTPException(status_code=404, detail="Table not found")
    
    result.pop('_id', None)
    if isinstance(result.get('created_at'), str):
        result['created_at'] = datetime.fromisoformat(result['created_at'])
    return Table(**result)

@api_router.get("/menu", response_model=List[MenuItem])
async def get_menu():
    menu_items = await db.menu_items.find({}, {"_id": 0}).to_list(1000)
    for item in menu_items:
        if isinstance(item.get('created_at'), str):
            item['created_at'] = datetime.fromisoformat(item['created_at'])
    return menu_items

@api_router.post("/menu", response_model=MenuItem)
async def create_menu_item(input: MenuItemCreate):
    menu_item_obj = MenuItem(**input.model_dump())
    doc = menu_item_obj.model_dump()
    doc['created_at'] = doc['created_at'].isoformat()
    await db.menu_items.insert_one(doc)
    return menu_item_obj

@api_router.put("/menu/{item_id}", response_model=MenuItem)
async def update_menu_item(item_id: str, input: MenuItemUpdate):
    update_data = {k: v for k, v in input.model_dump().items() if v is not None}
    if not update_data:
        raise HTTPException(status_code=400, detail="No fields to update")
    
    result = await db.menu_items.find_one_and_update(
        {"id": item_id},
        {"$set": update_data},
        return_document=True
    )
    
    if not result:
        raise HTTPException(status_code=404, detail="Menu item not found")
    
    result.pop('_id', None)
    if isinstance(result.get('created_at'), str):
        result['created_at'] = datetime.fromisoformat(result['created_at'])
    return MenuItem(**result)

@api_router.delete("/menu/{item_id}")
async def delete_menu_item(item_id: str):
    result = await db.menu_items.delete_one({"id": item_id})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Menu item not found")
    return {"message": "Menu item deleted successfully"}

@api_router.get("/orders", response_model=List[Order])
async def get_orders(status: Optional[str] = None):
    query = {}
    if status:
        query["status"] = status
    orders = await db.orders.find(query, {"_id": 0}).sort("created_at", -1).to_list(1000)
    for order in orders:
        if isinstance(order.get('created_at'), str):
            order['created_at'] = datetime.fromisoformat(order['created_at'])
        if isinstance(order.get('updated_at'), str):
            order['updated_at'] = datetime.fromisoformat(order['updated_at'])
    return orders

@api_router.get("/orders/{order_id}", response_model=Order)
async def get_order(order_id: str):
    order = await db.orders.find_one({"id": order_id}, {"_id": 0})
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    if isinstance(order.get('created_at'), str):
        order['created_at'] = datetime.fromisoformat(order['created_at'])
    if isinstance(order.get('updated_at'), str):
        order['updated_at'] = datetime.fromisoformat(order['updated_at'])
    return Order(**order)

@api_router.get("/orders/table/{table_id}", response_model=List[Order])
async def get_orders_by_table(table_id: str):
    orders = await db.orders.find({"table_id": table_id}, {"_id": 0}).sort("created_at", -1).to_list(1000)
    for order in orders:
        if isinstance(order.get('created_at'), str):
            order['created_at'] = datetime.fromisoformat(order['created_at'])
        if isinstance(order.get('updated_at'), str):
            order['updated_at'] = datetime.fromisoformat(order['updated_at'])
    return orders

@api_router.post("/orders", response_model=Order)
async def create_order(input: OrderCreate):
    # Check if there's an active order for this table (pending/preparing)
    existing_order = await db.orders.find_one(
        {"table_id": input.table_id, "status": {"$in": ["pending", "preparing", "ready"]}},
        {"_id": 0}
    )
    
    if existing_order:
        # Append new items to the existing order
        new_items = [item.model_dump() for item in input.items]
        existing_items = existing_order.get("items", [])
        
        # Merge items: if same menu_item_id exists, increase quantity; otherwise add new
        for new_item in new_items:
            found = False
            for existing_item in existing_items:
                if existing_item["menu_item_id"] == new_item["menu_item_id"]:
                    existing_item["quantity"] += new_item["quantity"]
                    found = True
                    break
            if not found:
                existing_items.append(new_item)
        
        new_total = sum(item["price"] * item["quantity"] for item in existing_items)
        new_notes = existing_order.get("notes", "")
        if input.notes:
            new_notes = f"{new_notes}\n{input.notes}".strip() if new_notes else input.notes
        
        # Reset status to pending so kitchen sees the updated order
        result = await db.orders.find_one_and_update(
            {"id": existing_order["id"]},
            {"$set": {
                "items": existing_items,
                "total_amount": new_total,
                "notes": new_notes,
                "status": "pending",
                "updated_at": datetime.now(timezone.utc).isoformat()
            }},
            return_document=True
        )
        result.pop('_id', None)
        if isinstance(result.get('created_at'), str):
            result['created_at'] = datetime.fromisoformat(result['created_at'])
        if isinstance(result.get('updated_at'), str):
            result['updated_at'] = datetime.fromisoformat(result['updated_at'])
        return Order(**result)
    
    # No active order exists - create a new one
    total = sum(item.price * item.quantity for item in input.items)
    order_obj = Order(**input.model_dump(), total_amount=total)
    doc = order_obj.model_dump()
    doc['created_at'] = doc['created_at'].isoformat()
    doc['updated_at'] = doc['updated_at'].isoformat()
    await db.orders.insert_one(doc)
    
    await db.tables.update_one(
        {"id": input.table_id},
        {"$set": {"status": TableStatus.occupied}}
    )
    
    return order_obj

@api_router.put("/orders/{order_id}", response_model=Order)
async def update_order_status(order_id: str, input: OrderStatusUpdate):
    update_data = {
        "status": input.status,
        "updated_at": datetime.now(timezone.utc).isoformat()
    }
    
    result = await db.orders.find_one_and_update(
        {"id": order_id},
        {"$set": update_data},
        return_document=True
    )
    
    if not result:
        raise HTTPException(status_code=404, detail="Order not found")
    
    result.pop('_id', None)
    if isinstance(result.get('created_at'), str):
        result['created_at'] = datetime.fromisoformat(result['created_at'])
    if isinstance(result.get('updated_at'), str):
        result['updated_at'] = datetime.fromisoformat(result['updated_at'])
    return Order(**result)

@api_router.get("/bills", response_model=List[Bill])
async def get_bills():
    bills = await db.bills.find({}, {"_id": 0}).sort("created_at", -1).to_list(1000)
    for bill in bills:
        if isinstance(bill.get('created_at'), str):
            bill['created_at'] = datetime.fromisoformat(bill['created_at'])
    return bills

@api_router.get("/bills/{bill_id}", response_model=Bill)
async def get_bill(bill_id: str):
    bill = await db.bills.find_one({"id": bill_id}, {"_id": 0})
    if not bill:
        raise HTTPException(status_code=404, detail="Bill not found")
    if isinstance(bill.get('created_at'), str):
        bill['created_at'] = datetime.fromisoformat(bill['created_at'])
    return Bill(**bill)

@api_router.post("/bills", response_model=Bill)
async def create_bill(input: BillCreate):
    order = await db.orders.find_one({"id": input.order_id}, {"_id": 0})
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    
    if isinstance(order.get('created_at'), str):
        order['created_at'] = datetime.fromisoformat(order['created_at'])
    if isinstance(order.get('updated_at'), str):
        order['updated_at'] = datetime.fromisoformat(order['updated_at'])
    
    order_obj = Order(**order)
    subtotal = order_obj.total_amount
    tax = subtotal * 0.18
    total = subtotal + tax
    
    bill_obj = Bill(
        order_id=input.order_id,
        table_id=order_obj.table_id,
        table_number=order_obj.table_number,
        items=order_obj.items,
        subtotal=subtotal,
        tax=tax,
        total=total,
        payment_method=input.payment_method
    )
    
    doc = bill_obj.model_dump()
    doc['created_at'] = doc['created_at'].isoformat()
    await db.bills.insert_one(doc)
    
    await db.orders.update_one(
        {"id": input.order_id},
        {"$set": {"status": OrderStatus.completed, "updated_at": datetime.now(timezone.utc).isoformat()}}
    )
    
    return bill_obj

@api_router.put("/bills/{bill_id}", response_model=Bill)
async def update_bill_payment(bill_id: str, input: BillPaymentUpdate):
    update_data = {
        "payment_status": input.payment_status,
        "payment_method": input.payment_method
    }
    
    result = await db.bills.find_one_and_update(
        {"id": bill_id},
        {"$set": update_data},
        return_document=True
    )
    
    if not result:
        raise HTTPException(status_code=404, detail="Bill not found")
    
    result.pop('_id', None)
    if isinstance(result.get('created_at'), str):
        result['created_at'] = datetime.fromisoformat(result['created_at'])
    
    if input.payment_status == PaymentStatus.paid:
        bill = Bill(**result)
        await db.tables.update_one(
            {"id": bill.table_id},
            {"$set": {"status": TableStatus.available}}
        )
    
    return Bill(**result)


# ============== OWNER / STAFF MANAGEMENT ==============

class SalaryType(str, Enum):
    monthly = "monthly"
    daily = "daily"

class AttendanceStatus(str, Enum):
    present = "present"
    absent = "absent"
    half_day = "half_day"

class Staff(BaseModel):
    model_config = ConfigDict(extra="ignore")
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    name: str
    role: str
    phone: str
    salary_type: SalaryType
    salary_amount: float
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

class StaffCreate(BaseModel):
    name: str
    role: str
    phone: str
    salary_type: SalaryType
    salary_amount: float

class StaffUpdate(BaseModel):
    name: Optional[str] = None
    role: Optional[str] = None
    phone: Optional[str] = None
    salary_type: Optional[SalaryType] = None
    salary_amount: Optional[float] = None

class Attendance(BaseModel):
    model_config = ConfigDict(extra="ignore")
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    staff_id: str
    staff_name: str
    date: str  # YYYY-MM-DD format
    status: AttendanceStatus

class AttendanceCreate(BaseModel):
    staff_id: str
    staff_name: str
    date: str
    status: AttendanceStatus

class SalaryRecord(BaseModel):
    model_config = ConfigDict(extra="ignore")
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    staff_id: str
    staff_name: str
    month: int
    year: int
    salary_type: SalaryType
    base_salary: float
    days_present: int
    half_days: int
    total_working_days: int
    calculated_salary: float
    generated_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

class SalaryGenerate(BaseModel):
    staff_id: str
    month: int
    year: int
    total_working_days: int

class OwnerPasswordVerify(BaseModel):
    password: str

class OwnerPasswordChange(BaseModel):
    current_password: str
    new_password: str

def hash_password(password: str) -> str:
    return hashlib.sha256(password.encode()).hexdigest()

# --- Owner Password ---
@api_router.post("/owner/verify")
async def verify_owner_password(input: OwnerPasswordVerify):
    settings = await db.settings.find_one({"key": "owner_password"}, {"_id": 0})
    if not settings:
        # Default password on first use
        default_hash = hash_password("owner123")
        await db.settings.insert_one({"key": "owner_password", "value": default_hash})
        settings = {"value": default_hash}

    if hash_password(input.password) == settings["value"]:
        return {"verified": True}
    raise HTTPException(status_code=401, detail="Invalid password")

@api_router.post("/owner/change-password")
async def change_owner_password(input: OwnerPasswordChange):
    settings = await db.settings.find_one({"key": "owner_password"}, {"_id": 0})
    if not settings or hash_password(input.current_password) != settings["value"]:
        raise HTTPException(status_code=401, detail="Current password is incorrect")

    await db.settings.update_one(
        {"key": "owner_password"},
        {"$set": {"value": hash_password(input.new_password)}}
    )
    return {"message": "Password changed successfully"}

# --- Staff CRUD ---
@api_router.get("/staff", response_model=List[Staff])
async def get_staff():
    staff = await db.staff.find({}, {"_id": 0}).to_list(1000)
    for s in staff:
        if isinstance(s.get('created_at'), str):
            s['created_at'] = datetime.fromisoformat(s['created_at'])
    return staff

@api_router.post("/staff", response_model=Staff)
async def create_staff(input: StaffCreate):
    staff_obj = Staff(**input.model_dump())
    doc = staff_obj.model_dump()
    doc['created_at'] = doc['created_at'].isoformat()
    await db.staff.insert_one(doc)
    return staff_obj

@api_router.put("/staff/{staff_id}", response_model=Staff)
async def update_staff(staff_id: str, input: StaffUpdate):
    update_data = {k: v for k, v in input.model_dump().items() if v is not None}
    if not update_data:
        raise HTTPException(status_code=400, detail="No fields to update")
    result = await db.staff.find_one_and_update(
        {"id": staff_id}, {"$set": update_data}, return_document=True
    )
    if not result:
        raise HTTPException(status_code=404, detail="Staff not found")
    result.pop('_id', None)
    if isinstance(result.get('created_at'), str):
        result['created_at'] = datetime.fromisoformat(result['created_at'])
    return Staff(**result)

@api_router.delete("/staff/{staff_id}")
async def delete_staff(staff_id: str):
    result = await db.staff.delete_one({"id": staff_id})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Staff not found")
    return {"message": "Staff deleted"}

# --- Attendance ---
@api_router.get("/attendance")
async def get_attendance(staff_id: Optional[str] = None, month: Optional[int] = None, year: Optional[int] = None):
    query = {}
    if staff_id:
        query["staff_id"] = staff_id
    if month and year:
        query["date"] = {"$regex": f"^{year}-{str(month).zfill(2)}"}
    records = await db.attendance.find(query, {"_id": 0}).to_list(10000)
    return records

@api_router.post("/attendance")
async def mark_attendance(input: AttendanceCreate):
    # Upsert: update if exists for same staff+date, otherwise insert
    existing = await db.attendance.find_one(
        {"staff_id": input.staff_id, "date": input.date}, {"_id": 0}
    )
    if existing:
        await db.attendance.update_one(
            {"staff_id": input.staff_id, "date": input.date},
            {"$set": {"status": input.status}}
        )
        existing["status"] = input.status
        return existing

    att_obj = Attendance(**input.model_dump())
    doc = att_obj.model_dump()
    await db.attendance.insert_one(doc)
    return att_obj.model_dump()

# --- Attendance Summary ---
@api_router.get("/attendance/summary/{staff_id}/{year}/{month}")
async def get_attendance_summary(staff_id: str, year: int, month: int):
    date_prefix = f"{year}-{str(month).zfill(2)}"
    records = await db.attendance.find(
        {"staff_id": staff_id, "date": {"$regex": f"^{date_prefix}"}},
        {"_id": 0}
    ).to_list(31)

    present = sum(1 for r in records if r["status"] == "present")
    absent = sum(1 for r in records if r["status"] == "absent")
    half_day = sum(1 for r in records if r["status"] == "half_day")

    return {
        "staff_id": staff_id,
        "month": month,
        "year": year,
        "days_present": present,
        "days_absent": absent,
        "half_days": half_day,
        "total_marked": len(records),
        "records": records
    }

# --- Salary ---
@api_router.get("/salary")
async def get_salaries(month: Optional[int] = None, year: Optional[int] = None):
    query = {}
    if month:
        query["month"] = month
    if year:
        query["year"] = year
    salaries = await db.salary_records.find(query, {"_id": 0}).sort("generated_at", -1).to_list(1000)
    for s in salaries:
        if isinstance(s.get('generated_at'), str):
            s['generated_at'] = datetime.fromisoformat(s['generated_at'])
    return salaries

@api_router.post("/salary/generate")
async def generate_salary(input: SalaryGenerate):
    # Get staff info
    staff = await db.staff.find_one({"id": input.staff_id}, {"_id": 0})
    if not staff:
        raise HTTPException(status_code=404, detail="Staff not found")

    # Get attendance summary
    date_prefix = f"{input.year}-{str(input.month).zfill(2)}"
    records = await db.attendance.find(
        {"staff_id": input.staff_id, "date": {"$regex": f"^{date_prefix}"}},
        {"_id": 0}
    ).to_list(31)

    days_present = sum(1 for r in records if r["status"] == "present")
    half_days = sum(1 for r in records if r["status"] == "half_day")

    # Calculate salary
    base = staff["salary_amount"]
    if staff["salary_type"] == "monthly":
        effective_days = days_present + (half_days * 0.5)
        calculated = (base / input.total_working_days) * effective_days if input.total_working_days > 0 else 0
    else:  # daily
        calculated = (base * days_present) + (base * 0.5 * half_days)

    calculated = round(calculated, 2)

    # Check if already generated
    existing = await db.salary_records.find_one(
        {"staff_id": input.staff_id, "month": input.month, "year": input.year},
        {"_id": 0}
    )
    if existing:
        # Update existing record
        await db.salary_records.update_one(
            {"staff_id": input.staff_id, "month": input.month, "year": input.year},
            {"$set": {
                "days_present": days_present,
                "half_days": half_days,
                "total_working_days": input.total_working_days,
                "calculated_salary": calculated,
                "generated_at": datetime.now(timezone.utc).isoformat()
            }}
        )
        existing.update({
            "days_present": days_present,
            "half_days": half_days,
            "total_working_days": input.total_working_days,
            "calculated_salary": calculated,
        })
        return existing

    salary_obj = SalaryRecord(
        staff_id=input.staff_id,
        staff_name=staff["name"],
        month=input.month,
        year=input.year,
        salary_type=staff["salary_type"],
        base_salary=base,
        days_present=days_present,
        half_days=half_days,
        total_working_days=input.total_working_days,
        calculated_salary=calculated
    )
    doc = salary_obj.model_dump()
    doc['generated_at'] = doc['generated_at'].isoformat()
    await db.salary_records.insert_one(doc)
    return salary_obj.model_dump()


app.include_router(api_router)

app.add_middleware(
    CORSMiddleware,
    allow_credentials=True,
    allow_origins=os.environ.get('CORS_ORIGINS', '*').split(','),
    allow_methods=["*"],
    allow_headers=["*"],
)

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

@app.on_event("shutdown")
async def shutdown_db_client():
    client.close()
