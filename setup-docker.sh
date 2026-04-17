#!/bin/bash

##############################################
#  DINE LOCAL HUB - Docker One-Click Setup   #
#  Simplest option: just needs Docker        #
##############################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     ${BOLD}DINE LOCAL HUB - Docker Setup${NC}${CYAN}            ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
echo ""

# Check Docker
if ! command -v docker &>/dev/null; then
    echo -e "${RED}[ERROR]${NC} Docker is not installed!"
    echo ""
    echo "Please install Docker first:"
    echo "  - Windows/Mac: https://www.docker.com/products/docker-desktop"
    echo "  - Linux: curl -fsSL https://get.docker.com | sh"
    echo ""
    exit 1
fi

if ! command -v docker-compose &>/dev/null && ! docker compose version &>/dev/null; then
    echo -e "${RED}[ERROR]${NC} Docker Compose is not installed!"
    exit 1
fi

# Get local IP
if [[ "$OSTYPE" == "darwin"* ]]; then
    LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "127.0.0.1")
else
    LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "127.0.0.1")
fi

echo -e "${GREEN}[OK]${NC} Docker found"
echo -e "${GREEN}[OK]${NC} Your Network IP: ${CYAN}${LOCAL_IP}${NC}"
echo ""

# Update docker-compose with the actual IP
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Replace HOST_IP placeholder in docker-compose
sed -i.bak "s/HOST_IP/$LOCAL_IP/g" docker-compose.yml 2>/dev/null || sed -i '' "s/HOST_IP/$LOCAL_IP/g" docker-compose.yml

echo -e "${YELLOW}[!!]${NC} Building and starting containers (this may take a few minutes on first run)..."
echo ""

# Start services
if docker compose version &>/dev/null; then
    docker compose up -d --build
else
    docker-compose up -d --build
fi

# Wait for services to start
echo ""
echo -e "${YELLOW}[!!]${NC} Waiting for services to start..."
sleep 10

# Seed database
echo -e "${YELLOW}[!!]${NC} Seeding database with sample data..."
if docker compose version &>/dev/null; then
    docker compose exec backend python seed_db.py
else
    docker-compose exec backend python seed_db.py
fi

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                              ║${NC}"
echo -e "${GREEN}║  ${BOLD}DINE LOCAL HUB IS RUNNING!${NC}${GREEN}                                  ║${NC}"
echo -e "${GREEN}║                                                              ║${NC}"
echo -e "${GREEN}║  ${BOLD}Your Network IP: ${NC}${CYAN}${LOCAL_IP}${NC}${GREEN}                                ║${NC}"
echo -e "${GREEN}║                                                              ║${NC}"
echo -e "${GREEN}║  Open on any device connected to your WiFi:                  ║${NC}"
echo -e "${GREEN}║                                                              ║${NC}"
echo -e "${GREEN}║  Captain (Phone):  ${CYAN}http://${LOCAL_IP}:3000/captain${NC}${GREEN}    ║${NC}"
echo -e "${GREEN}║  Kitchen (Tablet): ${CYAN}http://${LOCAL_IP}:3000/kitchen${NC}${GREEN}    ║${NC}"
echo -e "${GREEN}║  Billing (Desktop):${CYAN}http://${LOCAL_IP}:3000/billing${NC}${GREEN}    ║${NC}"
echo -e "${GREEN}║  Admin Panel:      ${CYAN}http://${LOCAL_IP}:3000/admin${NC}${GREEN}      ║${NC}"
echo -e "${GREEN}║                                                              ║${NC}"
echo -e "${GREEN}║  To stop:  docker compose down                               ║${NC}"
echo -e "${GREEN}║  To start: docker compose up -d                              ║${NC}"
echo -e "${GREEN}║                                                              ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
