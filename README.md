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

**Prerequisites** (install these first if you don't have them):
- **Python**: https://www.python.org/downloads/ (check "Add Python to PATH" during install)
- **Node.js**: https://nodejs.org/ (click the big green Download button)

**That's it! Now just:**
1. Double-click **`start.bat`**
2. It will automatically install everything else (MongoDB, packages, etc.)
3. First run takes 3-5 minutes. After that, it starts in ~30 seconds.
4. To stop: double-click **`stop.bat`**

> **Note:** MongoDB is downloaded automatically as a portable version — no installation needed. `setup-windows.bat` is optional and no longer required.

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
