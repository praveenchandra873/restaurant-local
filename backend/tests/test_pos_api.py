"""
Backend API Tests for Restaurant POS System
Tests: Tables, Menu, Orders, Bills, Owner/Staff Management
"""
import pytest
import requests
import os
import uuid

BASE_URL = os.environ.get('REACT_APP_BACKEND_URL', '').rstrip('/')

@pytest.fixture(scope="module")
def api_client():
    """Shared requests session"""
    session = requests.Session()
    session.headers.update({"Content-Type": "application/json"})
    return session

# ============== HEALTH CHECK ==============
class TestHealthCheck:
    """API Health Check"""
    
    def test_api_root(self, api_client):
        response = api_client.get(f"{BASE_URL}/api/")
        assert response.status_code == 200
        data = response.json()
        assert "message" in data
        assert data["message"] == "Restaurant POS API"
        print("✓ API root endpoint working")

# ============== TABLES API ==============
class TestTablesAPI:
    """Tables CRUD Tests"""
    
    def test_get_tables(self, api_client):
        response = api_client.get(f"{BASE_URL}/api/tables")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        print(f"✓ GET /api/tables - Found {len(data)} tables")
    
    def test_create_table(self, api_client):
        payload = {
            "table_number": f"TEST-{uuid.uuid4().hex[:6]}",
            "capacity": 4
        }
        response = api_client.post(f"{BASE_URL}/api/tables", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["table_number"] == payload["table_number"]
        assert data["capacity"] == payload["capacity"]
        assert data["status"] == "available"
        assert "id" in data
        print(f"✓ POST /api/tables - Created table {data['table_number']}")
        return data["id"]
    
    def test_update_table_status(self, api_client):
        # First create a table
        payload = {
            "table_number": f"TEST-{uuid.uuid4().hex[:6]}",
            "capacity": 2
        }
        create_response = api_client.post(f"{BASE_URL}/api/tables", json=payload)
        table_id = create_response.json()["id"]
        
        # Update status
        update_payload = {"status": "occupied"}
        response = api_client.put(f"{BASE_URL}/api/tables/{table_id}", json=update_payload)
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "occupied"
        print(f"✓ PUT /api/tables/{table_id} - Updated status to occupied")

# ============== MENU API ==============
class TestMenuAPI:
    """Menu CRUD Tests"""
    
    def test_get_menu(self, api_client):
        response = api_client.get(f"{BASE_URL}/api/menu")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        print(f"✓ GET /api/menu - Found {len(data)} menu items")
    
    def test_create_menu_item(self, api_client):
        payload = {
            "name": f"TEST-Item-{uuid.uuid4().hex[:6]}",
            "description": "Test menu item description",
            "category": "Main Course",
            "price": 299.99,
            "image": "https://example.com/test.jpg",
            "available": True
        }
        response = api_client.post(f"{BASE_URL}/api/menu", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == payload["name"]
        assert data["price"] == payload["price"]
        assert data["category"] == payload["category"]
        assert "id" in data
        print(f"✓ POST /api/menu - Created menu item {data['name']}")
        return data["id"]
    
    def test_update_menu_item(self, api_client):
        # First create a menu item
        payload = {
            "name": f"TEST-Update-{uuid.uuid4().hex[:6]}",
            "description": "Original description",
            "category": "Appetizer",
            "price": 150.00,
            "image": "https://example.com/test.jpg",
            "available": True
        }
        create_response = api_client.post(f"{BASE_URL}/api/menu", json=payload)
        item_id = create_response.json()["id"]
        
        # Update the item
        update_payload = {"price": 175.00, "available": False}
        response = api_client.put(f"{BASE_URL}/api/menu/{item_id}", json=update_payload)
        assert response.status_code == 200
        data = response.json()
        assert data["price"] == 175.00
        assert data["available"] == False
        print(f"✓ PUT /api/menu/{item_id} - Updated price and availability")
    
    def test_delete_menu_item(self, api_client):
        # First create a menu item
        payload = {
            "name": f"TEST-Delete-{uuid.uuid4().hex[:6]}",
            "description": "To be deleted",
            "category": "Dessert",
            "price": 100.00,
            "image": "https://example.com/test.jpg",
            "available": True
        }
        create_response = api_client.post(f"{BASE_URL}/api/menu", json=payload)
        item_id = create_response.json()["id"]
        
        # Delete the item
        response = api_client.delete(f"{BASE_URL}/api/menu/{item_id}")
        assert response.status_code == 200
        
        # Verify deletion - should return 404
        get_response = api_client.get(f"{BASE_URL}/api/menu")
        menu_items = get_response.json()
        assert not any(item["id"] == item_id for item in menu_items)
        print(f"✓ DELETE /api/menu/{item_id} - Menu item deleted")

# ============== ORDERS API ==============
class TestOrdersAPI:
    """Orders CRUD Tests"""
    
    @pytest.fixture
    def test_table(self, api_client):
        """Create a test table for orders"""
        payload = {
            "table_number": f"ORDER-TEST-{uuid.uuid4().hex[:6]}",
            "capacity": 4
        }
        response = api_client.post(f"{BASE_URL}/api/tables", json=payload)
        return response.json()
    
    @pytest.fixture
    def test_menu_item(self, api_client):
        """Create a test menu item for orders"""
        payload = {
            "name": f"TEST-Order-Item-{uuid.uuid4().hex[:6]}",
            "description": "Test item for orders",
            "category": "Main Course",
            "price": 250.00,
            "image": "https://example.com/test.jpg",
            "available": True
        }
        response = api_client.post(f"{BASE_URL}/api/menu", json=payload)
        return response.json()
    
    def test_get_orders(self, api_client):
        response = api_client.get(f"{BASE_URL}/api/orders")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        print(f"✓ GET /api/orders - Found {len(data)} orders")
    
    def test_create_order(self, api_client, test_table, test_menu_item):
        payload = {
            "table_id": test_table["id"],
            "table_number": test_table["table_number"],
            "items": [
                {
                    "menu_item_id": test_menu_item["id"],
                    "name": test_menu_item["name"],
                    "quantity": 2,
                    "price": test_menu_item["price"]
                }
            ],
            "notes": "Test order"
        }
        response = api_client.post(f"{BASE_URL}/api/orders", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["table_id"] == test_table["id"]
        assert data["status"] == "pending"
        assert data["total_amount"] == 500.00  # 2 * 250
        assert len(data["items"]) == 1
        print(f"✓ POST /api/orders - Created order for table {test_table['table_number']}")
        return data
    
    def test_update_order_status(self, api_client, test_table, test_menu_item):
        # Create an order first
        order_payload = {
            "table_id": test_table["id"],
            "table_number": test_table["table_number"],
            "items": [
                {
                    "menu_item_id": test_menu_item["id"],
                    "name": test_menu_item["name"],
                    "quantity": 1,
                    "price": test_menu_item["price"]
                }
            ],
            "notes": ""
        }
        create_response = api_client.post(f"{BASE_URL}/api/orders", json=order_payload)
        order_id = create_response.json()["id"]
        
        # Update to preparing
        response = api_client.put(f"{BASE_URL}/api/orders/{order_id}", json={"status": "preparing"})
        assert response.status_code == 200
        assert response.json()["status"] == "preparing"
        print(f"✓ PUT /api/orders/{order_id} - Status updated to preparing")
        
        # Update to ready
        response = api_client.put(f"{BASE_URL}/api/orders/{order_id}", json={"status": "ready"})
        assert response.status_code == 200
        assert response.json()["status"] == "ready"
        print(f"✓ PUT /api/orders/{order_id} - Status updated to ready")
    
    def test_get_order_by_id(self, api_client, test_table, test_menu_item):
        # Create an order
        order_payload = {
            "table_id": test_table["id"],
            "table_number": test_table["table_number"],
            "items": [
                {
                    "menu_item_id": test_menu_item["id"],
                    "name": test_menu_item["name"],
                    "quantity": 1,
                    "price": test_menu_item["price"]
                }
            ],
            "notes": ""
        }
        create_response = api_client.post(f"{BASE_URL}/api/orders", json=order_payload)
        order_id = create_response.json()["id"]
        
        # Get order by ID
        response = api_client.get(f"{BASE_URL}/api/orders/{order_id}")
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == order_id
        print(f"✓ GET /api/orders/{order_id} - Retrieved order successfully")

# ============== BILLS API ==============
class TestBillsAPI:
    """Bills CRUD Tests"""
    
    @pytest.fixture
    def completed_order(self, api_client):
        """Create a completed order for billing"""
        # Create table
        table_payload = {
            "table_number": f"BILL-TEST-{uuid.uuid4().hex[:6]}",
            "capacity": 4
        }
        table_response = api_client.post(f"{BASE_URL}/api/tables", json=table_payload)
        table = table_response.json()
        
        # Create menu item
        menu_payload = {
            "name": f"TEST-Bill-Item-{uuid.uuid4().hex[:6]}",
            "description": "Test item for billing",
            "category": "Main Course",
            "price": 300.00,
            "image": "https://example.com/test.jpg",
            "available": True
        }
        menu_response = api_client.post(f"{BASE_URL}/api/menu", json=menu_payload)
        menu_item = menu_response.json()
        
        # Create order
        order_payload = {
            "table_id": table["id"],
            "table_number": table["table_number"],
            "items": [
                {
                    "menu_item_id": menu_item["id"],
                    "name": menu_item["name"],
                    "quantity": 2,
                    "price": menu_item["price"]
                }
            ],
            "notes": ""
        }
        order_response = api_client.post(f"{BASE_URL}/api/orders", json=order_payload)
        order = order_response.json()
        
        # Mark order as ready
        api_client.put(f"{BASE_URL}/api/orders/{order['id']}", json={"status": "ready"})
        
        return order
    
    def test_get_bills(self, api_client):
        response = api_client.get(f"{BASE_URL}/api/bills")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        print(f"✓ GET /api/bills - Found {len(data)} bills")
    
    def test_create_bill(self, api_client, completed_order):
        payload = {
            "order_id": completed_order["id"],
            "payment_method": "Cash"
        }
        response = api_client.post(f"{BASE_URL}/api/bills", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["order_id"] == completed_order["id"]
        assert data["subtotal"] == 600.00  # 2 * 300
        assert data["tax"] == 108.00  # 18% of 600
        assert data["total"] == 708.00  # 600 + 108
        print(f"✓ POST /api/bills - Created bill with total ₹{data['total']}")
        return data
    
    def test_update_bill_payment(self, api_client, completed_order):
        # Create bill
        bill_payload = {
            "order_id": completed_order["id"],
            "payment_method": ""
        }
        bill_response = api_client.post(f"{BASE_URL}/api/bills", json=bill_payload)
        bill_id = bill_response.json()["id"]
        
        # Update payment
        update_payload = {
            "payment_status": "paid",
            "payment_method": "UPI"
        }
        response = api_client.put(f"{BASE_URL}/api/bills/{bill_id}", json=update_payload)
        assert response.status_code == 200
        data = response.json()
        assert data["payment_status"] == "paid"
        assert data["payment_method"] == "UPI"
        print(f"✓ PUT /api/bills/{bill_id} - Payment marked as paid via UPI")

# ============== OWNER API ==============
class TestOwnerAPI:
    """Owner Password and Staff Management Tests"""
    
    def test_verify_owner_password_correct(self, api_client):
        payload = {"password": "owner123"}
        response = api_client.post(f"{BASE_URL}/api/owner/verify", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["verified"] == True
        print("✓ POST /api/owner/verify - Correct password verified")
    
    def test_verify_owner_password_incorrect(self, api_client):
        payload = {"password": "wrongpassword"}
        response = api_client.post(f"{BASE_URL}/api/owner/verify", json=payload)
        assert response.status_code == 401
        print("✓ POST /api/owner/verify - Incorrect password rejected (401)")
    
    def test_get_staff(self, api_client):
        response = api_client.get(f"{BASE_URL}/api/staff")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        print(f"✓ GET /api/staff - Found {len(data)} staff members")
    
    def test_create_staff(self, api_client):
        payload = {
            "name": f"TEST-Staff-{uuid.uuid4().hex[:6]}",
            "role": "Waiter",
            "phone": "9876543210",
            "salary_type": "monthly",
            "salary_amount": 20000.00
        }
        response = api_client.post(f"{BASE_URL}/api/staff", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == payload["name"]
        assert data["role"] == payload["role"]
        assert data["salary_type"] == "monthly"
        print(f"✓ POST /api/staff - Created staff {data['name']}")
        return data["id"]
    
    def test_update_staff(self, api_client):
        # Create staff first
        create_payload = {
            "name": f"TEST-Update-Staff-{uuid.uuid4().hex[:6]}",
            "role": "Chef",
            "phone": "1234567890",
            "salary_type": "daily",
            "salary_amount": 800.00
        }
        create_response = api_client.post(f"{BASE_URL}/api/staff", json=create_payload)
        staff_id = create_response.json()["id"]
        
        # Update staff
        update_payload = {"salary_amount": 900.00}
        response = api_client.put(f"{BASE_URL}/api/staff/{staff_id}", json=update_payload)
        assert response.status_code == 200
        data = response.json()
        assert data["salary_amount"] == 900.00
        print(f"✓ PUT /api/staff/{staff_id} - Updated salary to ₹900")
    
    def test_delete_staff(self, api_client):
        # Create staff first
        create_payload = {
            "name": f"TEST-Delete-Staff-{uuid.uuid4().hex[:6]}",
            "role": "Helper",
            "phone": "5555555555",
            "salary_type": "daily",
            "salary_amount": 500.00
        }
        create_response = api_client.post(f"{BASE_URL}/api/staff", json=create_payload)
        staff_id = create_response.json()["id"]
        
        # Delete staff
        response = api_client.delete(f"{BASE_URL}/api/staff/{staff_id}")
        assert response.status_code == 200
        print(f"✓ DELETE /api/staff/{staff_id} - Staff deleted")

# ============== ATTENDANCE API ==============
class TestAttendanceAPI:
    """Attendance Management Tests"""
    
    @pytest.fixture
    def test_staff(self, api_client):
        """Create a test staff member"""
        payload = {
            "name": f"TEST-Attendance-Staff-{uuid.uuid4().hex[:6]}",
            "role": "Waiter",
            "phone": "9999999999",
            "salary_type": "monthly",
            "salary_amount": 25000.00
        }
        response = api_client.post(f"{BASE_URL}/api/staff", json=payload)
        return response.json()
    
    def test_mark_attendance(self, api_client, test_staff):
        payload = {
            "staff_id": test_staff["id"],
            "staff_name": test_staff["name"],
            "date": "2026-01-15",
            "status": "present"
        }
        response = api_client.post(f"{BASE_URL}/api/attendance", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "present"
        print(f"✓ POST /api/attendance - Marked {test_staff['name']} as present")
    
    def test_get_attendance(self, api_client, test_staff):
        # Mark attendance first
        payload = {
            "staff_id": test_staff["id"],
            "staff_name": test_staff["name"],
            "date": "2026-01-16",
            "status": "half_day"
        }
        api_client.post(f"{BASE_URL}/api/attendance", json=payload)
        
        # Get attendance
        response = api_client.get(f"{BASE_URL}/api/attendance?staff_id={test_staff['id']}")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        print(f"✓ GET /api/attendance - Found {len(data)} attendance records")
    
    def test_attendance_summary(self, api_client, test_staff):
        # Mark some attendance
        dates = ["2026-01-01", "2026-01-02", "2026-01-03"]
        statuses = ["present", "present", "half_day"]
        for date, status in zip(dates, statuses):
            payload = {
                "staff_id": test_staff["id"],
                "staff_name": test_staff["name"],
                "date": date,
                "status": status
            }
            api_client.post(f"{BASE_URL}/api/attendance", json=payload)
        
        # Get summary
        response = api_client.get(f"{BASE_URL}/api/attendance/summary/{test_staff['id']}/2026/1")
        assert response.status_code == 200
        data = response.json()
        assert "days_present" in data
        assert "half_days" in data
        print(f"✓ GET /api/attendance/summary - Present: {data['days_present']}, Half-days: {data['half_days']}")

# ============== SALARY API ==============
class TestSalaryAPI:
    """Salary Generation Tests"""
    
    @pytest.fixture
    def staff_with_attendance(self, api_client):
        """Create staff with attendance records"""
        # Create staff
        staff_payload = {
            "name": f"TEST-Salary-Staff-{uuid.uuid4().hex[:6]}",
            "role": "Chef",
            "phone": "8888888888",
            "salary_type": "monthly",
            "salary_amount": 30000.00
        }
        staff_response = api_client.post(f"{BASE_URL}/api/staff", json=staff_payload)
        staff = staff_response.json()
        
        # Mark attendance for 20 days
        for day in range(1, 21):
            payload = {
                "staff_id": staff["id"],
                "staff_name": staff["name"],
                "date": f"2026-01-{str(day).zfill(2)}",
                "status": "present" if day % 5 != 0 else "half_day"
            }
            api_client.post(f"{BASE_URL}/api/attendance", json=payload)
        
        return staff
    
    def test_generate_salary(self, api_client, staff_with_attendance):
        payload = {
            "staff_id": staff_with_attendance["id"],
            "month": 1,
            "year": 2026,
            "total_working_days": 26
        }
        response = api_client.post(f"{BASE_URL}/api/salary/generate", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["staff_id"] == staff_with_attendance["id"]
        assert data["month"] == 1
        assert data["year"] == 2026
        assert "calculated_salary" in data
        print(f"✓ POST /api/salary/generate - Calculated salary: ₹{data['calculated_salary']}")
    
    def test_get_salaries(self, api_client):
        response = api_client.get(f"{BASE_URL}/api/salary")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        print(f"✓ GET /api/salary - Found {len(data)} salary records")


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
