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

# Category images
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

MENU_ITEMS = [
    # Starter
    ("French Fries", "Classic salted french fries", "Starter", 90),
    ("French Fries (Peri Peri)", "Spicy peri peri seasoned fries", "Starter", 100),
    ("French Fries (Cheese)", "Fries topped with melted cheese", "Starter", 110),
    ("Hot N Sour Soup", "Tangy and spicy vegetable soup", "Starter", 90),
    ("Manchow Soup", "Crispy noodle topped Chinese soup", "Starter", 90),

    # Maggi
    ("Plain Maggi", "Classic Maggi noodles", "Maggi", 60),
    ("Plain Maggi Double Masala", "Extra spicy Maggi", "Maggi", 70),
    ("Plain Cheese Maggi", "Maggi with melted cheese", "Maggi", 70),
    ("Vegetable Maggi", "Maggi with mixed vegetables", "Maggi", 80),
    ("Vegetable Cheese Maggi", "Veggie Maggi with cheese", "Maggi", 90),
    ("Cheese Corn Maggi", "Maggi with cheese and sweet corn", "Maggi", 90),
    ("Corn Butter Maggi", "Butter corn flavored Maggi", "Maggi", 90),
    ("Schezwan Maggi", "Spicy Schezwan style Maggi", "Maggi", 90),
    ("Cheese Chilly Maggi", "Chilly cheese Maggi", "Maggi", 90),
    ("Veg Peri Peri Maggi", "Peri peri spiced vegetable Maggi", "Maggi", 90),
    ("Veg Paneer Maggi", "Maggi with paneer chunks", "Maggi", 100),

    # Sandwich
    ("Bombay Sandwich", "Classic Mumbai style sandwich", "Sandwich", 70),
    ("Veg Sandwich", "Mixed vegetable sandwich", "Sandwich", 70),
    ("Bombay Cheese Sandwich", "Bombay sandwich with extra cheese", "Sandwich", 80),
    ("Veg Cheese Sandwich", "Veggie sandwich with cheese", "Sandwich", 80),
    ("Cheese Corn Sandwich", "Corn and cheese grilled sandwich", "Sandwich", 80),
    ("Cheese Chilly Corn Sandwich", "Spicy corn cheese sandwich", "Sandwich", 90),
    ("Cheese Garlic Sandwich", "Garlic butter cheese sandwich", "Sandwich", 90),
    ("Peri Peri Cheese Corn Sandwich", "Peri peri corn cheese sandwich", "Sandwich", 90),
    ("Paneer Peri Peri Sandwich", "Paneer with peri peri spice", "Sandwich", 100),
    ("Paneer Cheese Sandwich", "Paneer and cheese grilled sandwich", "Sandwich", 100),
    ("Paneer Makhani Sandwich", "Paneer makhani filling sandwich", "Sandwich", 100),
    ("Chocolate Sandwich", "Sweet chocolate filled sandwich", "Sandwich", 100),
    ("Cheese Chocolate Sandwich", "Chocolate and cheese combo", "Sandwich", 110),

    # Pasta
    ("Indian Pasta", "Desi masala style pasta", "Pasta", 130),
    ("Red Sauce Pasta", "Classic tomato red sauce pasta", "Pasta", 140),
    ("White Pasta", "Creamy white sauce pasta", "Pasta", 150),
    ("Makhan Sauce Pasta", "Butter makhani sauce pasta", "Pasta", 160),
    ("Red & White Sauce Pasta", "Mixed sauce pasta", "Pasta", 160),

    # Rice
    ("Veg Fried Rice", "Classic vegetable fried rice", "Rice", 170),
    ("Veg Peri-Peri Fried Rice", "Spicy peri peri fried rice", "Rice", 180),
    ("Schezwan Rice", "Spicy Schezwan fried rice", "Rice", 180),
    ("Veg Paneer Rice", "Fried rice with paneer", "Rice", 200),
    ("Paneer-65 Rice", "Fried rice with paneer 65", "Rice", 210),
    ("Mongolian Rice", "Indo-Chinese Mongolian rice", "Rice", 230),
    ("Veg Biryani", "Aromatic vegetable biryani", "Rice", 230),

    # Chinese
    ("Veg Chowmein/Noodles", "Classic vegetable noodles", "Chinese", 140),
    ("Hakka Noodles", "Indo-Chinese hakka noodles", "Chinese", 160),
    ("Chilly Garlic Noodles", "Spicy garlic flavored noodles", "Chinese", 160),
    ("Schezwan Noodles", "Hot Schezwan sauce noodles", "Chinese", 160),
    ("Crispy Corn", "Golden fried crispy corn kernels", "Chinese", 180),
    ("Chana Chilly", "Spicy chilli chickpeas", "Chinese", 180),
    ("Chana Roast", "Roasted spicy chickpeas", "Chinese", 180),
    ("Veg Manchurian", "Vegetable manchurian in gravy", "Chinese", 160),
    ("Crispy Corn Chilly", "Spicy crispy corn", "Chinese", 190),
    ("Baby Corn Chilly", "Chilli baby corn stir fry", "Chinese", 190),
    ("Gobi Chilly", "Spicy cauliflower chilli", "Chinese", 190),
    ("Paneer Chilly", "Indo-Chinese paneer chilli", "Chinese", 190),
    ("Mushroom Chilly", "Spicy mushroom stir fry", "Chinese", 200),
    ("Paneer 65", "Crispy spiced paneer", "Chinese", 210),

    # Mocktail
    ("Virgin Mojito", "Classic lime and mint mojito", "Mocktail", 80),
    ("Blue Lagoon Mojito", "Blue curacao flavored mojito", "Mocktail", 80),
    ("Green Apple Mojito", "Refreshing green apple mojito", "Mocktail", 80),
    ("Kiwi Mojito", "Fresh kiwi flavored mojito", "Mocktail", 80),
    ("Mango Mojito", "Sweet mango mojito", "Mocktail", 80),
    ("Water Melon Mojito", "Refreshing watermelon mojito", "Mocktail", 90),
    ("Long Ice Tea", "Classic long island iced tea", "Mocktail", 90),
    ("Peach Ice Tea", "Peach flavored iced tea", "Mocktail", 90),

    # Cold Coffee
    ("Cold Coffee (Regular)", "Classic cold coffee", "Cold Coffee", 90),
    ("Cold Coffee with Ice Cream", "Cold coffee with a scoop of ice cream", "Cold Coffee", 110),
    ("Oreo Milkshake", "Creamy Oreo cookie milkshake", "Cold Coffee", 110),
    ("Chocolate Milkshake", "Rich chocolate milkshake", "Cold Coffee", 110),
    ("Strawberry Milkshake", "Fresh strawberry milkshake", "Cold Coffee", 110),
    ("Mango Milkshake", "Sweet mango milkshake", "Cold Coffee", 110),
    ("Kiwi Milkshake", "Kiwi flavored milkshake", "Cold Coffee", 110),
    ("Pineapple Shake", "Tropical pineapple shake", "Cold Coffee", 110),
    ("Green Apple Milkshake", "Tangy green apple milkshake", "Cold Coffee", 110),
    ("Butterscotch Milkshake", "Butterscotch flavored milkshake", "Cold Coffee", 110),
    ("Kitkat Milkshake", "Kitkat chocolate milkshake", "Cold Coffee", 110),
    ("Black Currant Milkshake", "Black currant milkshake", "Cold Coffee", 110),
    ("Blueberry Milkshake", "Blueberry flavored milkshake", "Cold Coffee", 110),
    ("Vanilla Milkshake", "Classic vanilla milkshake", "Cold Coffee", 110),
    ("Bubble Gum Milkshake", "Fun bubblegum milkshake", "Cold Coffee", 110),
    ("Kitkat Cold Coffee", "Cold coffee with Kitkat", "Cold Coffee", 110),
    ("Cold Coffee without Ice", "Cold coffee served without ice", "Cold Coffee", 110),

    # Combo
    ("Sandwich + Cold Coffee", "Any sandwich with cold coffee", "Combo", 160),
    ("Maggi + Cold Coffee", "Any Maggi with cold coffee", "Combo", 170),
    ("Veg Chowmien + Mojito", "Chowmein with any mojito", "Combo", 210),
    ("Veg Chowmien + Cold Coffee", "Chowmein with cold coffee", "Combo", 220),
    ("Veg Manchurian + Veg Fried Rice", "Manchurian with fried rice", "Combo", 280),
    ("Veg Chowmien + Manchurian", "Noodles with manchurian", "Combo", 300),
    ("Paneer Chilly + Veg Fried Rice", "Paneer chilly with fried rice", "Combo", 300),
    ("Paneer Chilly + Manchurian", "Paneer chilly with manchurian", "Combo", 330),
    ("Veg Chowmien + Paneer Chilly", "Noodles with paneer chilly", "Combo", 330),
    ("Paneer Chilly + Schezwan Rice", "Paneer chilly with schezwan rice", "Combo", 330),
]

async def add_menu_items():
    print("Adding Nanhe Cafe menu items...")
    
    # Clear existing menu items only
    await db.menu_items.delete_many({})
    print("Cleared old menu items")
    
    docs = []
    for name, desc, category, price in MENU_ITEMS:
        docs.append({
            "id": str(uuid.uuid4()),
            "name": name,
            "description": desc,
            "category": category,
            "price": float(price),
            "image": IMAGES.get(category, IMAGES["Starter"]),
            "available": True,
            "created_at": "2026-01-01T00:00:00+00:00"
        })
    
    await db.menu_items.insert_many(docs)
    print(f"Added {len(docs)} menu items:")
    
    # Print summary by category
    from collections import Counter
    cats = Counter(item[2] for item in MENU_ITEMS)
    for cat, count in cats.items():
        print(f"  {cat}: {count} items")
    
    print("\nDone!")
    client.close()

if __name__ == "__main__":
    asyncio.run(add_menu_items())
