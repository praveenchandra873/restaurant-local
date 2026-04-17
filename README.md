# Dine Local Hub - Restaurant Management System

A complete restaurant order management system that runs on your local network. Captains take orders on phones, kitchen sees them instantly, and billing generates bills - all synchronized in real-time.

---

## Quick Setup Guide (Pick ONE method)

### Method 1: Docker (Easiest - Recommended)

**Only need to install ONE thing:** [Docker Desktop](https://www.docker.com/products/docker-desktop)

```
# Linux / Mac
chmod +x setup-docker.sh
./setup-docker.sh

# Windows (in PowerShell)
bash setup-docker.sh
```

### Method 2: Direct Install - Mac / Linux

```
chmod +x setup.sh
./setup.sh
```

Then to start every day:
```
./start.sh
```

### Method 3: Direct Install - Windows

1. **Double-click `setup-windows.bat`**
2. A permission popup will appear — click **Yes**
3. A new window opens and installs everything (5-10 minutes first time)
4. When done, it shows "SETUP COMPLETE" with your network URLs
5. To start every day: **double-click `start.bat`**
6. To stop: **double-click `stop.bat`**

> **Important:** Do NOT close the minimized DLH windows that appear when you run `start.bat` — those are the running services.

---

## How It Works

Once running, open these URLs on **any device connected to your restaurant WiFi**:

| Role | URL | Device |
|------|-----|--------|
| Captain/Waiter | `http://YOUR_IP:3000/captain` | Phone/Tablet |
| Kitchen Display | `http://YOUR_IP:3000/kitchen` | Tablet/Screen |
| Billing Counter | `http://YOUR_IP:3000/billing` | Desktop/Laptop |
| Admin Panel | `http://YOUR_IP:3000/admin` | Desktop/Laptop |

> The setup script will show you YOUR_IP automatically. It's your computer's network address (e.g., 192.168.1.100).

**Tip:** On phones, open the URL in Chrome/Safari and tap **"Add to Home Screen"** to make it feel like a native app!

---

## Features

- **Captain App** - Browse menu, add items to cart, place orders for specific tables, add more items to existing orders
- **Kitchen Display** - Real-time order grid with color-coded wait times (green/yellow/red), mark orders as preparing or ready
- **Billing Dashboard** - View ready orders, generate bills with 18% tax, mark as paid (Cash/Card/UPI), payment history
- **Admin Panel** - Add/edit/delete menu items, manage tables, toggle item availability

---

## Stopping the System

```
# Docker
docker compose down

# Mac/Linux
./stop.sh

# Windows
double-click stop.bat
```

---

## Troubleshooting

**Q: Devices can't connect / ERR_CONNECTION_REFUSED?**
- Run `stop.bat` first, then run `start.bat` again (uses updated scripts with firewall fix)
- If still not working, run `setup-windows.bat` again — it now adds firewall rules automatically
- Make sure all devices are on the **same WiFi network**
- Try `http://localhost:3000/captain` on the server computer first — if that works but the IP doesn't, it's a firewall issue
- Manual firewall fix: Windows Settings → Firewall → Allow an app → Allow "Node.js" and "Python" on Private networks

**Q: How to find my IP address?**
- Mac: System Preferences → Network → Your IP is shown
- Windows: Open CMD → type `ipconfig` → look for "IPv4 Address"
- Linux: Run `hostname -I`

**Q: Data disappeared after restart?**
- If using Docker: Data is stored in a Docker volume, it persists
- If using direct install: Data is in MongoDB, it persists as long as MongoDB is running

**Q: Want to change the menu?**
- Go to `http://YOUR_IP:3000/admin` → Menu Items tab → Add/Edit/Delete items
