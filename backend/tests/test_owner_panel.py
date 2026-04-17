"""
Owner Panel API Tests
Tests for: Owner password verification, Staff CRUD, Attendance, Salary generation
"""
import pytest
import requests
import os
import uuid

BASE_URL = os.environ.get('REACT_APP_BACKEND_URL', '').rstrip('/')

class TestOwnerPasswordVerification:
    """Test owner password gate functionality"""
    
    def test_verify_correct_password(self):
        """Test that correct password 'owner123' grants access"""
        response = requests.post(f"{BASE_URL}/api/owner/verify", json={"password": "owner123"})
        assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
        data = response.json()
        assert data.get("verified") == True, f"Expected verified=True, got {data}"
        print("PASS: Correct password verification works")
    
    def test_verify_wrong_password(self):
        """Test that wrong password returns 401"""
        response = requests.post(f"{BASE_URL}/api/owner/verify", json={"password": "wrongpassword"})
        assert response.status_code == 401, f"Expected 401, got {response.status_code}"
        print("PASS: Wrong password returns 401")
    
    def test_verify_empty_password(self):
        """Test that empty password returns error"""
        response = requests.post(f"{BASE_URL}/api/owner/verify", json={"password": ""})
        assert response.status_code == 401, f"Expected 401, got {response.status_code}"
        print("PASS: Empty password returns 401")


class TestStaffCRUD:
    """Test Staff CRUD operations"""
    
    @pytest.fixture(autouse=True)
    def setup(self):
        """Setup test data prefix"""
        self.test_prefix = "TEST_"
    
    def test_get_staff_list(self):
        """Test fetching staff list"""
        response = requests.get(f"{BASE_URL}/api/staff")
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"
        data = response.json()
        assert isinstance(data, list), "Expected list response"
        print(f"PASS: Get staff list - found {len(data)} staff members")
    
    def test_create_staff_monthly(self):
        """Test creating a staff member with monthly salary"""
        staff_data = {
            "name": f"{self.test_prefix}John Doe",
            "role": "Chef",
            "phone": "9876543210",
            "salary_type": "monthly",
            "salary_amount": 25000
        }
        response = requests.post(f"{BASE_URL}/api/staff", json=staff_data)
        assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
        
        data = response.json()
        assert data["name"] == staff_data["name"]
        assert data["role"] == staff_data["role"]
        assert data["phone"] == staff_data["phone"]
        assert data["salary_type"] == "monthly"
        assert data["salary_amount"] == 25000
        assert "id" in data
        
        # Verify persistence with GET
        get_response = requests.get(f"{BASE_URL}/api/staff")
        staff_list = get_response.json()
        created_staff = next((s for s in staff_list if s["id"] == data["id"]), None)
        assert created_staff is not None, "Created staff not found in list"
        assert created_staff["name"] == staff_data["name"]
        
        print(f"PASS: Create monthly staff - ID: {data['id']}")
        return data["id"]
    
    def test_create_staff_daily(self):
        """Test creating a staff member with daily salary"""
        staff_data = {
            "name": f"{self.test_prefix}Jane Smith",
            "role": "Waiter",
            "phone": "9876543211",
            "salary_type": "daily",
            "salary_amount": 800
        }
        response = requests.post(f"{BASE_URL}/api/staff", json=staff_data)
        assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
        
        data = response.json()
        assert data["salary_type"] == "daily"
        assert data["salary_amount"] == 800
        
        print(f"PASS: Create daily staff - ID: {data['id']}")
        return data["id"]
    
    def test_update_staff(self):
        """Test updating a staff member"""
        # First create a staff
        staff_data = {
            "name": f"{self.test_prefix}Update Test",
            "role": "Helper",
            "phone": "9876543212",
            "salary_type": "monthly",
            "salary_amount": 15000
        }
        create_response = requests.post(f"{BASE_URL}/api/staff", json=staff_data)
        assert create_response.status_code == 200
        staff_id = create_response.json()["id"]
        
        # Update the staff
        update_data = {
            "name": f"{self.test_prefix}Updated Name",
            "salary_amount": 18000
        }
        update_response = requests.put(f"{BASE_URL}/api/staff/{staff_id}", json=update_data)
        assert update_response.status_code == 200, f"Expected 200, got {update_response.status_code}"
        
        updated = update_response.json()
        assert updated["name"] == update_data["name"]
        assert updated["salary_amount"] == 18000
        
        # Verify persistence
        get_response = requests.get(f"{BASE_URL}/api/staff")
        staff_list = get_response.json()
        found_staff = next((s for s in staff_list if s["id"] == staff_id), None)
        assert found_staff["name"] == update_data["name"]
        assert found_staff["salary_amount"] == 18000
        
        print(f"PASS: Update staff - ID: {staff_id}")
    
    def test_delete_staff(self):
        """Test deleting a staff member"""
        # First create a staff
        staff_data = {
            "name": f"{self.test_prefix}Delete Test",
            "role": "Cleaner",
            "phone": "9876543213",
            "salary_type": "daily",
            "salary_amount": 500
        }
        create_response = requests.post(f"{BASE_URL}/api/staff", json=staff_data)
        assert create_response.status_code == 200
        staff_id = create_response.json()["id"]
        
        # Delete the staff
        delete_response = requests.delete(f"{BASE_URL}/api/staff/{staff_id}")
        assert delete_response.status_code == 200, f"Expected 200, got {delete_response.status_code}"
        
        # Verify deletion
        get_response = requests.get(f"{BASE_URL}/api/staff")
        staff_list = get_response.json()
        found_staff = next((s for s in staff_list if s["id"] == staff_id), None)
        assert found_staff is None, "Staff should be deleted"
        
        print(f"PASS: Delete staff - ID: {staff_id}")
    
    def test_delete_nonexistent_staff(self):
        """Test deleting a non-existent staff returns 404"""
        response = requests.delete(f"{BASE_URL}/api/staff/nonexistent-id-12345")
        assert response.status_code == 404, f"Expected 404, got {response.status_code}"
        print("PASS: Delete non-existent staff returns 404")


class TestAttendance:
    """Test Attendance marking and summary"""
    
    @pytest.fixture
    def test_staff(self):
        """Create a test staff member for attendance tests"""
        staff_data = {
            "name": f"TEST_Attendance Staff {uuid.uuid4().hex[:6]}",
            "role": "Waiter",
            "phone": "9876543220",
            "salary_type": "monthly",
            "salary_amount": 20000
        }
        response = requests.post(f"{BASE_URL}/api/staff", json=staff_data)
        assert response.status_code == 200
        return response.json()
    
    def test_mark_attendance_present(self, test_staff):
        """Test marking attendance as present"""
        attendance_data = {
            "staff_id": test_staff["id"],
            "staff_name": test_staff["name"],
            "date": "2026-01-15",
            "status": "present"
        }
        response = requests.post(f"{BASE_URL}/api/attendance", json=attendance_data)
        assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
        
        data = response.json()
        assert data["staff_id"] == test_staff["id"]
        assert data["status"] == "present"
        print(f"PASS: Mark attendance present for {test_staff['name']}")
    
    def test_mark_attendance_half_day(self, test_staff):
        """Test marking attendance as half day"""
        attendance_data = {
            "staff_id": test_staff["id"],
            "staff_name": test_staff["name"],
            "date": "2026-01-16",
            "status": "half_day"
        }
        response = requests.post(f"{BASE_URL}/api/attendance", json=attendance_data)
        assert response.status_code == 200
        
        data = response.json()
        assert data["status"] == "half_day"
        print(f"PASS: Mark attendance half_day for {test_staff['name']}")
    
    def test_mark_attendance_absent(self, test_staff):
        """Test marking attendance as absent"""
        attendance_data = {
            "staff_id": test_staff["id"],
            "staff_name": test_staff["name"],
            "date": "2026-01-17",
            "status": "absent"
        }
        response = requests.post(f"{BASE_URL}/api/attendance", json=attendance_data)
        assert response.status_code == 200
        
        data = response.json()
        assert data["status"] == "absent"
        print(f"PASS: Mark attendance absent for {test_staff['name']}")
    
    def test_update_attendance_same_date(self, test_staff):
        """Test updating attendance for same date (upsert)"""
        # First mark as present
        attendance_data = {
            "staff_id": test_staff["id"],
            "staff_name": test_staff["name"],
            "date": "2026-01-18",
            "status": "present"
        }
        requests.post(f"{BASE_URL}/api/attendance", json=attendance_data)
        
        # Update to absent
        attendance_data["status"] = "absent"
        response = requests.post(f"{BASE_URL}/api/attendance", json=attendance_data)
        assert response.status_code == 200
        
        data = response.json()
        assert data["status"] == "absent", "Attendance should be updated to absent"
        print("PASS: Update attendance for same date works (upsert)")
    
    def test_get_attendance_summary(self, test_staff):
        """Test getting attendance summary for a staff member"""
        # Mark some attendance
        for day, status in [(1, "present"), (2, "present"), (3, "half_day"), (4, "absent")]:
            requests.post(f"{BASE_URL}/api/attendance", json={
                "staff_id": test_staff["id"],
                "staff_name": test_staff["name"],
                "date": f"2026-01-{str(day).zfill(2)}",
                "status": status
            })
        
        # Get summary
        response = requests.get(f"{BASE_URL}/api/attendance/summary/{test_staff['id']}/2026/1")
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"
        
        data = response.json()
        assert data["staff_id"] == test_staff["id"]
        assert data["month"] == 1
        assert data["year"] == 2026
        assert "days_present" in data
        assert "days_absent" in data
        assert "half_days" in data
        assert "records" in data
        
        print(f"PASS: Get attendance summary - Present: {data['days_present']}, Half: {data['half_days']}, Absent: {data['days_absent']}")


class TestSalaryGeneration:
    """Test Salary calculation and generation"""
    
    @pytest.fixture
    def monthly_staff(self):
        """Create a monthly salary staff member"""
        staff_data = {
            "name": f"TEST_Monthly Salary {uuid.uuid4().hex[:6]}",
            "role": "Chef",
            "phone": "9876543230",
            "salary_type": "monthly",
            "salary_amount": 30000
        }
        response = requests.post(f"{BASE_URL}/api/staff", json=staff_data)
        assert response.status_code == 200
        return response.json()
    
    @pytest.fixture
    def daily_staff(self):
        """Create a daily salary staff member"""
        staff_data = {
            "name": f"TEST_Daily Salary {uuid.uuid4().hex[:6]}",
            "role": "Helper",
            "phone": "9876543231",
            "salary_type": "daily",
            "salary_amount": 1000
        }
        response = requests.post(f"{BASE_URL}/api/staff", json=staff_data)
        assert response.status_code == 200
        return response.json()
    
    def test_generate_salary_monthly(self, monthly_staff):
        """Test salary generation for monthly staff"""
        # Mark attendance: 20 present, 3 half days
        for day in range(1, 21):
            requests.post(f"{BASE_URL}/api/attendance", json={
                "staff_id": monthly_staff["id"],
                "staff_name": monthly_staff["name"],
                "date": f"2026-01-{str(day).zfill(2)}",
                "status": "present"
            })
        for day in range(21, 24):
            requests.post(f"{BASE_URL}/api/attendance", json={
                "staff_id": monthly_staff["id"],
                "staff_name": monthly_staff["name"],
                "date": f"2026-01-{str(day).zfill(2)}",
                "status": "half_day"
            })
        
        # Generate salary
        salary_data = {
            "staff_id": monthly_staff["id"],
            "month": 1,
            "year": 2026,
            "total_working_days": 26
        }
        response = requests.post(f"{BASE_URL}/api/salary/generate", json=salary_data)
        assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
        
        data = response.json()
        assert data["staff_id"] == monthly_staff["id"]
        assert data["month"] == 1
        assert data["year"] == 2026
        assert data["salary_type"] == "monthly"
        assert data["base_salary"] == 30000
        assert data["days_present"] == 20
        assert data["half_days"] == 3
        assert data["total_working_days"] == 26
        
        # Verify calculation: (30000/26) * (20 + 3*0.5) = (30000/26) * 21.5
        expected_salary = round((30000 / 26) * 21.5, 2)
        assert abs(data["calculated_salary"] - expected_salary) < 1, f"Expected ~{expected_salary}, got {data['calculated_salary']}"
        
        print(f"PASS: Monthly salary generated - Calculated: ₹{data['calculated_salary']}")
    
    def test_generate_salary_daily(self, daily_staff):
        """Test salary generation for daily staff"""
        # Mark attendance: 15 present, 5 half days
        for day in range(1, 16):
            requests.post(f"{BASE_URL}/api/attendance", json={
                "staff_id": daily_staff["id"],
                "staff_name": daily_staff["name"],
                "date": f"2026-01-{str(day).zfill(2)}",
                "status": "present"
            })
        for day in range(16, 21):
            requests.post(f"{BASE_URL}/api/attendance", json={
                "staff_id": daily_staff["id"],
                "staff_name": daily_staff["name"],
                "date": f"2026-01-{str(day).zfill(2)}",
                "status": "half_day"
            })
        
        # Generate salary
        salary_data = {
            "staff_id": daily_staff["id"],
            "month": 1,
            "year": 2026,
            "total_working_days": 26
        }
        response = requests.post(f"{BASE_URL}/api/salary/generate", json=salary_data)
        assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
        
        data = response.json()
        assert data["salary_type"] == "daily"
        assert data["base_salary"] == 1000
        assert data["days_present"] == 15
        assert data["half_days"] == 5
        
        # Verify calculation: (1000 * 15) + (1000 * 0.5 * 5) = 15000 + 2500 = 17500
        expected_salary = (1000 * 15) + (1000 * 0.5 * 5)
        assert data["calculated_salary"] == expected_salary, f"Expected {expected_salary}, got {data['calculated_salary']}"
        
        print(f"PASS: Daily salary generated - Calculated: ₹{data['calculated_salary']}")
    
    def test_get_salary_records(self, monthly_staff):
        """Test fetching salary records"""
        # Generate a salary first
        requests.post(f"{BASE_URL}/api/salary/generate", json={
            "staff_id": monthly_staff["id"],
            "month": 1,
            "year": 2026,
            "total_working_days": 26
        })
        
        # Get salary records
        response = requests.get(f"{BASE_URL}/api/salary?month=1&year=2026")
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"
        
        data = response.json()
        assert isinstance(data, list)
        print(f"PASS: Get salary records - found {len(data)} records")
    
    def test_generate_salary_nonexistent_staff(self):
        """Test generating salary for non-existent staff returns 404"""
        salary_data = {
            "staff_id": "nonexistent-staff-id",
            "month": 1,
            "year": 2026,
            "total_working_days": 26
        }
        response = requests.post(f"{BASE_URL}/api/salary/generate", json=salary_data)
        assert response.status_code == 404, f"Expected 404, got {response.status_code}"
        print("PASS: Generate salary for non-existent staff returns 404")


class TestCleanup:
    """Cleanup test data"""
    
    def test_cleanup_test_staff(self):
        """Delete all TEST_ prefixed staff"""
        response = requests.get(f"{BASE_URL}/api/staff")
        if response.status_code == 200:
            staff_list = response.json()
            deleted_count = 0
            for staff in staff_list:
                if staff["name"].startswith("TEST_"):
                    del_response = requests.delete(f"{BASE_URL}/api/staff/{staff['id']}")
                    if del_response.status_code == 200:
                        deleted_count += 1
            print(f"CLEANUP: Deleted {deleted_count} test staff members")
        assert True  # Always pass cleanup


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
