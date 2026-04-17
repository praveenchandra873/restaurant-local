#!/bin/bash

##############################################
#  DINE LOCAL HUB - One-Click Setup Script   #
#  For Linux & macOS                         #
##############################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

print_banner() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                              ║${NC}"
    echo -e "${CYAN}║     ${BOLD}DINE LOCAL HUB${NC}${CYAN}                           ║${NC}"
    echo -e "${CYAN}║     Restaurant Management System             ║${NC}"
    echo -e "${CYAN}║     One-Click Setup                          ║${NC}"
    echo -e "${CYAN}║                                              ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
    echo ""
}

log_info() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[!!]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  Step $1: $2${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        if command -v apt-get &>/dev/null; then
            PKG_MANAGER="apt"
        elif command -v yum &>/dev/null; then
            PKG_MANAGER="yum"
        elif command -v dnf &>/dev/null; then
            PKG_MANAGER="dnf"
        else
            PKG_MANAGER="unknown"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="mac"
        PKG_MANAGER="brew"
    else
        OS="unknown"
        PKG_MANAGER="unknown"
    fi
    log_info "Detected OS: $OS (Package Manager: $PKG_MANAGER)"
}

get_local_ip() {
    if [[ "$OS" == "mac" ]]; then
        LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "127.0.0.1")
    else
        LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "127.0.0.1")
    fi
    echo "$LOCAL_IP"
}

install_homebrew() {
    if [[ "$OS" == "mac" ]] && ! command -v brew &>/dev/null; then
        log_warn "Homebrew not found. Installing..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        log_info "Homebrew installed"
    fi
}

install_mongodb() {
    if command -v mongod &>/dev/null; then
        log_info "MongoDB is already installed"
        return
    fi

    log_warn "MongoDB not found. Installing..."

    if [[ "$OS" == "mac" ]]; then
        brew tap mongodb/brew
        brew install mongodb-community
        brew services start mongodb-community
    elif [[ "$PKG_MANAGER" == "apt" ]]; then
        # Import MongoDB public GPG key
        curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg 2>/dev/null || true
        echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs 2>/dev/null || echo "jammy")/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
        sudo apt-get update
        sudo apt-get install -y mongodb-org
        sudo systemctl start mongod
        sudo systemctl enable mongod
    elif [[ "$PKG_MANAGER" == "yum" || "$PKG_MANAGER" == "dnf" ]]; then
        cat <<MONGOEOF | sudo tee /etc/yum.repos.d/mongodb-org-7.0.repo
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc
MONGOEOF
        sudo $PKG_MANAGER install -y mongodb-org
        sudo systemctl start mongod
        sudo systemctl enable mongod
    fi

    log_info "MongoDB installed and started"
}

install_python() {
    if command -v python3 &>/dev/null; then
        PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
        log_info "Python $PYTHON_VERSION is already installed"
        return
    fi

    log_warn "Python not found. Installing..."

    if [[ "$OS" == "mac" ]]; then
        brew install python@3.11
    elif [[ "$PKG_MANAGER" == "apt" ]]; then
        sudo apt-get update
        sudo apt-get install -y python3 python3-pip python3-venv
    elif [[ "$PKG_MANAGER" == "yum" || "$PKG_MANAGER" == "dnf" ]]; then
        sudo $PKG_MANAGER install -y python3 python3-pip
    fi

    log_info "Python installed"
}

install_nodejs() {
    if command -v node &>/dev/null; then
        NODE_VERSION=$(node --version 2>&1)
        log_info "Node.js $NODE_VERSION is already installed"
        return
    fi

    log_warn "Node.js not found. Installing..."

    if [[ "$OS" == "mac" ]]; then
        brew install node
    elif [[ "$PKG_MANAGER" == "apt" ]]; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install -y nodejs
    elif [[ "$PKG_MANAGER" == "yum" || "$PKG_MANAGER" == "dnf" ]]; then
        curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
        sudo $PKG_MANAGER install -y nodejs
    fi

    log_info "Node.js installed"
}

install_yarn() {
    if command -v yarn &>/dev/null; then
        log_info "Yarn is already installed"
        return
    fi

    log_warn "Yarn not found. Installing..."
    npm install -g yarn
    log_info "Yarn installed"
}

setup_backend() {
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    cd "$SCRIPT_DIR/backend"

    # Create virtual environment
    python3 -m venv venv 2>/dev/null || python3 -m pip install virtualenv && python3 -m virtualenv venv
    source venv/bin/activate

    # Install dependencies
    pip install --upgrade pip
    pip install -r requirements.txt

    # Create .env file
    cat > .env << ENVEOF
MONGO_URL=mongodb://localhost:27017
DB_NAME=dine_local_hub
CORS_ORIGINS=*
ENVEOF

    log_info "Backend setup complete"

    # Seed the database
    python seed_db.py
    log_info "Database seeded with sample data"

    deactivate
}

setup_frontend() {
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    LOCAL_IP=$(get_local_ip)
    cd "$SCRIPT_DIR/frontend"

    # Install dependencies
    yarn install

    # Create .env file pointing to local backend
    cat > .env << ENVEOF
REACT_APP_BACKEND_URL=http://${LOCAL_IP}:8001
ENVEOF

    log_info "Frontend setup complete"
}

create_start_script() {
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    LOCAL_IP=$(get_local_ip)

    cat > "$SCRIPT_DIR/start.sh" << 'STARTEOF'
#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get local IP
if [[ "$OSTYPE" == "darwin"* ]]; then
    LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "127.0.0.1")
else
    LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "127.0.0.1")
fi

# Update frontend .env with current IP
cat > "$SCRIPT_DIR/frontend/.env" << EOF
REACT_APP_BACKEND_URL=http://${LOCAL_IP}:8001
EOF

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     ${BOLD}DINE LOCAL HUB - Starting...${NC}${CYAN}             ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
echo ""

# Start MongoDB (if not running)
if ! pgrep -x "mongod" > /dev/null; then
    echo -e "${YELLOW}[!!]${NC} Starting MongoDB..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew services start mongodb-community 2>/dev/null || mongod --fork --logpath /tmp/mongod.log
    else
        sudo systemctl start mongod 2>/dev/null || mongod --fork --logpath /tmp/mongod.log
    fi
fi
echo -e "${GREEN}[OK]${NC} MongoDB running"

# Start Backend
cd "$SCRIPT_DIR/backend"
source venv/bin/activate
echo -e "${GREEN}[OK]${NC} Starting Backend on port 8001..."
uvicorn server:app --host 0.0.0.0 --port 8001 --reload &
BACKEND_PID=$!
sleep 2

# Start Frontend
cd "$SCRIPT_DIR/frontend"
echo -e "${GREEN}[OK]${NC} Starting Frontend on port 3000..."
PORT=3000 HOST=0.0.0.0 yarn start &
FRONTEND_PID=$!
sleep 5

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                              ║${NC}"
echo -e "${CYAN}║  ${BOLD}DINE LOCAL HUB IS RUNNING!${NC}${CYAN}                                  ║${NC}"
echo -e "${CYAN}║                                                              ║${NC}"
echo -e "${CYAN}║  ${BOLD}Your Network IP: ${NC}${GREEN}${LOCAL_IP}${NC}${CYAN}                                ║${NC}"
echo -e "${CYAN}║                                                              ║${NC}"
echo -e "${CYAN}║  Open these URLs on any device connected to your WiFi:       ║${NC}"
echo -e "${CYAN}║                                                              ║${NC}"
echo -e "${CYAN}║  ${BOLD}Captain (Phone):${NC}  http://${LOCAL_IP}:3000/captain    ${CYAN}║${NC}"
echo -e "${CYAN}║  ${BOLD}Kitchen (Tablet):${NC} http://${LOCAL_IP}:3000/kitchen    ${CYAN}║${NC}"
echo -e "${CYAN}║  ${BOLD}Billing (Desktop):${NC}http://${LOCAL_IP}:3000/billing    ${CYAN}║${NC}"
echo -e "${CYAN}║  ${BOLD}Admin Panel:${NC}      http://${LOCAL_IP}:3000/admin      ${CYAN}║${NC}"
echo -e "${CYAN}║                                                              ║${NC}"
echo -e "${CYAN}║  Press Ctrl+C to stop all services                           ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Handle Ctrl+C to stop all services
cleanup() {
    echo ""
    echo -e "${YELLOW}[!!]${NC} Shutting down services..."
    kill $BACKEND_PID 2>/dev/null
    kill $FRONTEND_PID 2>/dev/null
    echo -e "${GREEN}[OK]${NC} All services stopped. Goodbye!"
    exit 0
}

trap cleanup SIGINT SIGTERM

# Wait for processes
wait
STARTEOF

    chmod +x "$SCRIPT_DIR/start.sh"
    log_info "Start script created (start.sh)"

    # Create stop script
    cat > "$SCRIPT_DIR/stop.sh" << 'STOPEOF'
#!/bin/bash
echo "Stopping Dine Local Hub..."
pkill -f "uvicorn server:app" 2>/dev/null
pkill -f "react-scripts start" 2>/dev/null
echo "All services stopped."
STOPEOF

    chmod +x "$SCRIPT_DIR/stop.sh"
    log_info "Stop script created (stop.sh)"
}

print_success() {
    LOCAL_IP=$(get_local_ip)
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                              ║${NC}"
    echo -e "${GREEN}║  ${BOLD}SETUP COMPLETE!${NC}${GREEN}                                              ║${NC}"
    echo -e "${GREEN}║                                                              ║${NC}"
    echo -e "${GREEN}║  ${BOLD}Your Network IP: ${NC}${CYAN}${LOCAL_IP}${NC}${GREEN}                                ║${NC}"
    echo -e "${GREEN}║                                                              ║${NC}"
    echo -e "${GREEN}║  To start the system, simply run:                            ║${NC}"
    echo -e "${GREEN}║                                                              ║${NC}"
    echo -e "${GREEN}║    ${BOLD}./start.sh${NC}${GREEN}                                                  ║${NC}"
    echo -e "${GREEN}║                                                              ║${NC}"
    echo -e "${GREEN}║  Then open on any device connected to your WiFi:             ║${NC}"
    echo -e "${GREEN}║                                                              ║${NC}"
    echo -e "${GREEN}║  Captain (Phone):  ${CYAN}http://${LOCAL_IP}:3000/captain${NC}${GREEN}    ║${NC}"
    echo -e "${GREEN}║  Kitchen (Tablet): ${CYAN}http://${LOCAL_IP}:3000/kitchen${NC}${GREEN}    ║${NC}"
    echo -e "${GREEN}║  Billing (Desktop):${CYAN}http://${LOCAL_IP}:3000/billing${NC}${GREEN}    ║${NC}"
    echo -e "${GREEN}║  Admin Panel:      ${CYAN}http://${LOCAL_IP}:3000/admin${NC}${GREEN}      ║${NC}"
    echo -e "${GREEN}║                                                              ║${NC}"
    echo -e "${GREEN}║  To stop: ${BOLD}./stop.sh${NC}${GREEN}                                          ║${NC}"
    echo -e "${GREEN}║                                                              ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ==================== MAIN ====================

print_banner

log_step "1" "Detecting your system"
detect_os

if [[ "$OS" == "unknown" ]]; then
    log_error "Unsupported operating system. Please use Linux or macOS."
    log_error "For Windows, please run setup-windows.ps1 instead."
    exit 1
fi

log_step "2" "Installing MongoDB (Database)"
if [[ "$OS" == "mac" ]]; then
    install_homebrew
fi
install_mongodb

log_step "3" "Installing Python (Backend Server)"
install_python

log_step "4" "Installing Node.js & Yarn (Frontend)"
install_nodejs
install_yarn

log_step "5" "Setting up Backend"
setup_backend

log_step "6" "Setting up Frontend"
setup_frontend

log_step "7" "Creating startup scripts"
create_start_script

print_success
