from fastapi import FastAPI, APIRouter, HTTPException
from dotenv import load_dotenv
from starlette.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient
import os
import logging
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
