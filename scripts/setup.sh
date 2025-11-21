#!/bin/bash

# Smart Classroom Watch - Setup Script
# This script sets up the complete development environment

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Smart Classroom Watch - Setup${NC}"
echo -e "${BLUE}================================${NC}\n"

# Function to print status
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    print_error "Please don't run this script as root"
    exit 1
fi

# Check system
print_info "Checking system requirements..."

# Check Node.js
if command -v node &> /dev/null; then
    NODE_VERSION=$(node -v)
    print_status "Node.js installed: $NODE_VERSION"
else
    print_error "Node.js not found. Please install Node.js v14 or higher"
    exit 1
fi

# Check npm
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm -v)
    print_status "npm installed: $NPM_VERSION"
else
    print_error "npm not found"
    exit 1
fi

# Check Python
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    print_status "Python installed: $PYTHON_VERSION"
else
    print_error "Python 3 not found. Please install Python 3.8+"
    exit 1
fi

# Check PlatformIO (optional for firmware)
if command -v pio &> /dev/null; then
    print_status "PlatformIO installed"
else
    print_info "PlatformIO not found (optional for firmware development)"
fi

echo ""

# Setup Backend
echo -e "${BLUE}Setting up Backend...${NC}"
cd backend/

if [ -f "package.json" ]; then
    print_info "Installing backend dependencies..."
    npm install
    print_status "Backend dependencies installed"
else
    print_error "Backend package.json not found"
fi

if [ -f "requirements.txt" ]; then
    print_info "Installing Python dependencies..."
    pip3 install -r requirements.txt
    print_status "Python dependencies installed"
fi

# Create .env file if not exists
if [ ! -f ".env" ]; then
    print_info "Creating .env file..."
    cat > .env << EOF
NODE_ENV=development
PORT=5000
DATABASE_URL=mongodb://localhost:27017/smart_classroom
JWT_SECRET=$(openssl rand -hex 32)
MQTT_BROKER=mqtt://localhost:1883
REDIS_URL=redis://localhost:6379
EOF
    print_status ".env file created"
else
    print_info ".env file already exists"
fi

cd ..

# Setup Mobile Apps
echo -e "\n${BLUE}Setting up Mobile Apps...${NC}"

# Student App
if [ -d "mobile-app/student-app" ]; then
    cd mobile-app/student-app/
    print_info "Installing student app dependencies..."
    npm install
    print_status "Student app dependencies installed"
    cd ../..
fi

# Teacher App
if [ -d "mobile-app/teacher-app" ]; then
    cd mobile-app/teacher-app/
    print_info "Installing teacher app dependencies..."
    npm install
    print_status "Teacher app dependencies installed"
    cd ../..
fi

# Setup Web Dashboard
echo -e "\n${BLUE}Setting up Web Dashboard...${NC}"

if [ -d "web-dashboard/teacher-dashboard" ]; then
    cd web-dashboard/teacher-dashboard/
    print_info "Installing teacher dashboard dependencies..."
    npm install
    print_status "Teacher dashboard dependencies installed"
    cd ../..
fi

if [ -d "web-dashboard/admin-dashboard" ]; then
    cd web-dashboard/admin-dashboard/
    print_info "Installing admin dashboard dependencies..."
    npm install
    print_status "Admin dashboard dependencies installed"
    cd ../..
fi

# Setup Firmware (if PlatformIO is installed)
if command -v pio &> /dev/null; then
    echo -e "\n${BLUE}Setting up Firmware...${NC}"
    cd firmware/
    print_info "Installing firmware dependencies..."
    pio lib install
    print_status "Firmware libraries installed"
    cd ..
fi

# Setup Database
echo -e "\n${BLUE}Setting up Database...${NC}"

# Check if MongoDB is running
if command -v mongod &> /dev/null; then
    if pgrep -x "mongod" > /dev/null; then
        print_status "MongoDB is running"
    else
        print_info "MongoDB is not running. Start it with: sudo systemctl start mongod"
    fi
else
    print_info "MongoDB not found. Please install MongoDB"
fi

# Check if PostgreSQL is available (alternative)
if command -v psql &> /dev/null; then
    print_status "PostgreSQL is available"
    
    # Ask user if they want to create database
    read -p "Do you want to create the database schema? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Creating database schema..."
        cd backend/database/
        psql -U postgres -f schema.sql
        print_status "Database schema created"
        cd ../..
    fi
fi

# Setup Tests
echo -e "\n${BLUE}Setting up Tests...${NC}"

cd tests/backend/
print_info "Installing test dependencies..."
npm install
print_status "Test dependencies installed"
cd ../..

# Create necessary directories
echo -e "\n${BLUE}Creating directories...${NC}"
mkdir -p logs/
mkdir -p uploads/
mkdir -p backups/
print_status "Directories created"

# Set permissions
chmod +x scripts/*.sh
print_status "Script permissions set"

# Final instructions
echo -e "\n${GREEN}================================${NC}"
echo -e "${GREEN}Setup Complete! 🎉${NC}"
echo -e "${GREEN}================================${NC}\n"

echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Configure your .env file in backend/"
echo "2. Start MongoDB: ${BLUE}sudo systemctl start mongod${NC}"
echo "3. Start backend: ${BLUE}cd backend && npm run dev${NC}"
echo "4. Start web dashboard: ${BLUE}cd web-dashboard/teacher-dashboard && npm start${NC}"
echo "5. For firmware: ${BLUE}cd firmware && pio run --target upload${NC}"

echo -e "\n${YELLOW}Documentation:${NC}"
echo "- Backend API: http://localhost:5000"
echo "- Teacher Dashboard: http://localhost:3000"
echo "- API Docs: http://localhost:5000/api-docs"

echo -e "\n${GREEN}Happy coding! 🚀${NC}\n"
