import requests
import sys
import json
from datetime import datetime

class RestaurantPOSAPITester:
    def __init__(self, base_url="https://dine-local-hub-1.preview.emergentagent.com"):
        self.base_url = base_url
        self.api_url = f"{base_url}/api"
        self.tests_run = 0
        self.tests_passed = 0
        self.test_results = []
        self.created_items = {
            'tables': [],
            'menu_items': [],
            'orders': [],
            'bills': []
        }

    def log_test(self, name, success, details=""):
        """Log test result"""
        self.tests_run += 1
        if success:
            self.tests_passed += 1
            print(f"✅ {name}")
        else:
            print(f"❌ {name} - {details}")
        
        self.test_results.append({
            'test': name,
            'success': success,
            'details': details
        })

    def run_test(self, name, method, endpoint, expected_status, data=None, headers=None):
        """Run a single API test"""
        url = f"{self.api_url}/{endpoint}"
        if headers is None:
            headers = {'Content-Type': 'application/json'}

        try:
            if method == 'GET':
                response = requests.get(url, headers=headers, timeout=10)
            elif method == 'POST':
                response = requests.post(url, json=data, headers=headers, timeout=10)
            elif method == 'PUT':
                response = requests.put(url, json=data, headers=headers, timeout=10)
            elif method == 'DELETE':
                response = requests.delete(url, headers=headers, timeout=10)

            success = response.status_code == expected_status
            details = f"Status: {response.status_code}"
            
            if not success:
                details += f" (Expected {expected_status})"
                try:
                    error_data = response.json()
                    details += f" - {error_data.get('detail', 'Unknown error')}"
                except:
                    details += f" - {response.text[:100]}"

            self.log_test(name, success, details)
            
            if success:
                try:
                    return response.json()
                except:
                    return {}
            return None

        except Exception as e:
            self.log_test(name, False, f"Error: {str(e)}")
            return None

    def test_root_endpoint(self):
        """Test root API endpoint"""
        return self.run_test("Root API endpoint", "GET", "", 200)

    def test_get_tables(self):
        """Test getting all tables"""
        result = self.run_test("Get all tables", "GET", "tables", 200)
        if result is not None:
            print(f"   Found {len(result)} tables")
            return result
        return []

    def test_create_table(self):
        """Test creating a new table"""
        table_data = {
            "table_number": f"TEST-{datetime.now().strftime('%H%M%S')}",
            "capacity": 4
        }
        result = self.run_test("Create table", "POST", "tables", 200, table_data)
        if result:
            self.created_items['tables'].append(result['id'])
            print(f"   Created table: {result['table_number']}")
            return result
        return None

    def test_update_table(self, table_id):
        """Test updating table status"""
        update_data = {"status": "occupied"}
        result = self.run_test("Update table status", "PUT", f"tables/{table_id}", 200, update_data)
        if result:
            print(f"   Updated table status to: {result['status']}")
        return result

    def test_get_menu(self):
        """Test getting menu items"""
        result = self.run_test("Get menu items", "GET", "menu", 200)
        if result is not None:
            print(f"   Found {len(result)} menu items")
            return result
        return []

    def test_create_menu_item(self):
        """Test creating a new menu item"""
        menu_data = {
            "name": f"Test Dish {datetime.now().strftime('%H%M%S')}",
            "description": "A delicious test dish",
            "category": "Main Course",
            "price": 299.99,
            "image": "https://images.unsplash.com/photo-1762922425232-ab2b6b251739?crop=entropy&cs=srgb&fm=jpg&ixid=M3w3NDk1NzZ8MHwxfHNlYXJjaHwxfHxnb3VybWV0JTIwZm9vZCUyMHBsYXRlJTIwdG9wJTIwdmlld3xlbnwwfHx8fDE3NzY0MDMxMDh8MA&ixlib=rb-4.1.0&q=85",
            "available": True
        }
        result = self.run_test("Create menu item", "POST", "menu", 200, menu_data)
        if result:
            self.created_items['menu_items'].append(result['id'])
            print(f"   Created menu item: {result['name']}")
            return result
        return None

    def test_update_menu_item(self, item_id):
        """Test updating menu item"""
        update_data = {"available": False}
        result = self.run_test("Update menu item", "PUT", f"menu/{item_id}", 200, update_data)
        if result:
            print(f"   Updated menu item availability to: {result['available']}")
        return result

    def test_delete_menu_item(self, item_id):
        """Test deleting menu item"""
        result = self.run_test("Delete menu item", "DELETE", f"menu/{item_id}", 200)
        if result:
            print(f"   Deleted menu item successfully")
        return result

    def test_create_order(self, table_id, table_number, menu_items):
        """Test creating an order"""
        if not menu_items:
            print("   Skipping order creation - no menu items available")
            return None
            
        order_items = []
        for item in menu_items[:2]:  # Use first 2 menu items
            order_items.append({
                "menu_item_id": item['id'],
                "name": item['name'],
                "quantity": 2,
                "price": item['price']
            })

        order_data = {
            "table_id": table_id,
            "table_number": table_number,
            "items": order_items,
            "notes": "Test order from API testing"
        }
        
        result = self.run_test("Create order", "POST", "orders", 200, order_data)
        if result:
            self.created_items['orders'].append(result['id'])
            print(f"   Created order for table {table_number} with {len(order_items)} items")
            return result
        return None

    def test_get_orders(self):
        """Test getting all orders"""
        result = self.run_test("Get all orders", "GET", "orders", 200)
        if result is not None:
            print(f"   Found {len(result)} orders")
            return result
        return []

    def test_get_order_by_id(self, order_id):
        """Test getting specific order"""
        result = self.run_test("Get order by ID", "GET", f"orders/{order_id}", 200)
        if result:
            print(f"   Retrieved order: {result['id']}")
        return result

    def test_update_order_status(self, order_id):
        """Test updating order status"""
        status_data = {"status": "preparing"}
        result = self.run_test("Update order status to preparing", "PUT", f"orders/{order_id}", 200, status_data)
        if result:
            print(f"   Updated order status to: {result['status']}")
            
            # Update to ready
            status_data = {"status": "ready"}
            result = self.run_test("Update order status to ready", "PUT", f"orders/{order_id}", 200, status_data)
            if result:
                print(f"   Updated order status to: {result['status']}")
        return result

    def test_create_bill(self, order_id):
        """Test creating a bill"""
        bill_data = {
            "order_id": order_id,
            "payment_method": "Cash"
        }
        result = self.run_test("Create bill", "POST", "bills", 200, bill_data)
        if result:
            self.created_items['bills'].append(result['id'])
            print(f"   Created bill: ₹{result['total']:.2f}")
            return result
        return None

    def test_get_bills(self):
        """Test getting all bills"""
        result = self.run_test("Get all bills", "GET", "bills", 200)
        if result is not None:
            print(f"   Found {len(result)} bills")
            return result
        return []

    def test_update_bill_payment(self, bill_id):
        """Test updating bill payment status"""
        payment_data = {
            "payment_status": "paid",
            "payment_method": "Card"
        }
        result = self.run_test("Update bill payment", "PUT", f"bills/{bill_id}", 200, payment_data)
        if result:
            print(f"   Updated bill payment status to: {result['payment_status']}")
        return result

    def run_comprehensive_test(self):
        """Run all tests in sequence"""
        print("🚀 Starting Restaurant POS API Testing...")
        print("=" * 60)

        # Test basic connectivity
        self.test_root_endpoint()
        
        # Test Tables
        print("\n📋 Testing Tables API...")
        existing_tables = self.test_get_tables()
        new_table = self.test_create_table()
        if new_table:
            self.test_update_table(new_table['id'])

        # Test Menu
        print("\n🍽️ Testing Menu API...")
        existing_menu = self.test_get_menu()
        new_menu_item = self.test_create_menu_item()
        if new_menu_item:
            self.test_update_menu_item(new_menu_item['id'])
            # Don't delete immediately, we need it for order testing

        # Test Orders
        print("\n📝 Testing Orders API...")
        if new_table and (existing_menu or new_menu_item):
            menu_for_order = existing_menu if existing_menu else [new_menu_item]
            new_order = self.test_create_order(new_table['id'], new_table['table_number'], menu_for_order)
            if new_order:
                self.test_get_orders()
                self.test_get_order_by_id(new_order['id'])
                self.test_update_order_status(new_order['id'])
                
                # Test Bills
                print("\n💰 Testing Bills API...")
                new_bill = self.test_create_bill(new_order['id'])
                if new_bill:
                    self.test_get_bills()
                    self.test_update_bill_payment(new_bill['id'])

        # Clean up created menu item
        if new_menu_item:
            self.test_delete_menu_item(new_menu_item['id'])

        # Print summary
        print("\n" + "=" * 60)
        print(f"📊 Test Summary: {self.tests_passed}/{self.tests_run} tests passed")
        
        if self.tests_passed == self.tests_run:
            print("🎉 All tests passed! API is working correctly.")
            return True
        else:
            print("⚠️ Some tests failed. Check the details above.")
            return False

def main():
    tester = RestaurantPOSAPITester()
    success = tester.run_comprehensive_test()
    
    # Save detailed results
    with open('/app/test_reports/backend_api_results.json', 'w') as f:
        json.dump({
            'timestamp': datetime.now().isoformat(),
            'total_tests': tester.tests_run,
            'passed_tests': tester.tests_passed,
            'success_rate': (tester.tests_passed / tester.tests_run * 100) if tester.tests_run > 0 else 0,
            'test_results': tester.test_results,
            'created_items': tester.created_items
        }, f, indent=2)
    
    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())