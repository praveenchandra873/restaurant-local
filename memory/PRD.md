# Dine Local Hub - Restaurant POS System

## Original Problem Statement
Create an app for a restaurant which runs locally inside their restaurant network so that for each table as soon as any captain takes the order of any specific table it goes directly to billing counter and update the items in real time.

## Architecture
- **Frontend**: React + Tailwind CSS + Shadcn UI
- **Backend**: FastAPI (Python)
- **Database**: MongoDB (local)
- **Real-time**: Polling (5 second intervals)

## User Personas
1. **Captain/Waiter** - Takes orders at tables using mobile/tablet
2. **Kitchen Staff** - Views and manages orders on kitchen display
3. **Billing Counter** - Generates bills and processes payments on desktop
4. **Admin** - Manages menu items, tables, and system settings

## Core Requirements (Static)
- Real-time order placement & updates
- Bill generation & payment tracking
- Order history
- Table management
- Menu management

## What's Been Implemented (April 17, 2026)
### MVP Features
- Role-based home screen with 4 modules
- Captain App: Browse menu, add to cart, place orders, **add more items to existing order**
- Kitchen Display: Real-time order grid, color-coded wait times, status updates (pending → preparing → ready)
- Billing Dashboard: View ready orders, generate bills with 18% tax, mark paid (Cash/Card/UPI), paid bills history table
- Admin Panel: Table management (add tables), Menu management (add/edit/delete items, toggle availability)

### Bug Fix (April 17, 2026)
- Fixed: Captain can now add more items to an occupied table's existing order (single order approach - items append to existing order)

## Setup Scripts Created (April 17, 2026)
- `setup.sh` - One-click setup for Linux/Mac (installs MongoDB, Python, Node.js, configures everything)
- `setup-windows.ps1` - One-click setup for Windows (uses Chocolatey to install dependencies)
- `setup-docker.sh` + `docker-compose.yml` - Docker-based setup (simplest, only needs Docker)
- `start.sh` / `start.bat` - Auto-generated daily startup scripts
- `stop.sh` / `stop.bat` - Stop all services
- `README.md` - Non-technical guide with all 3 setup methods

## Prioritized Backlog
### P0 (Critical)
- All core features implemented ✅

### P1 (Important)
- Order item-level modifications (remove individual items from existing order)
- Print receipt functionality
- Daily sales report/summary

### P2 (Nice to Have)
- Staff authentication/login per role
- Kitchen order priority/rush feature
- Discount/coupon support
- Multiple tax rate configurations
- Order history search/filter by date
