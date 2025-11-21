#!/bin/bash

# Smart Classroom Watch - Deployment Script
# Deploys the application to production server

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
DEPLOY_ENV=${1:-production}
SERVER_USER=${SERVER_USER:-ubuntu}
SERVER_HOST=${SERVER_HOST:-your-server.com}
APP_DIR=${APP_DIR:-/var/www/smart-classroom-watch}
BRANCH=${2:-main}

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Smart Classroom Watch - Deploy${NC}"
echo -e "${BLUE}Environment: ${DEPLOY_ENV}${NC}"
echo -e "${BLUE}================================${NC}\n"

print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# Confirmation
if [ "$DEPLOY_ENV" = "production" ]; then
    read -p "⚠️  Deploy to PRODUCTION? (yes/no): " -r
    if [[ ! $REPLY =~ ^yes$ ]]; then
        echo "Deployment cancelled"
        exit 0
    fi
fi

# Pre-deployment checks
echo -e "${BLUE}Running pre-deployment checks...${NC}"

# Check if git repo is clean
if [[ -n $(git status -s) ]]; then
    print_error "Git repository has uncommitted changes"
    exit 1
fi
print_status "Git repository is clean"

# Check branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "$BRANCH" ]; then
    print_error "Not on branch $BRANCH (currently on $CURRENT_BRANCH)"
    exit 1
fi
print_status "On correct branch: $BRANCH"

# Pull latest changes
print_info "Pulling latest changes..."
git pull origin $BRANCH
print_status "Latest changes pulled"

# Run tests
echo -e "\n${BLUE}Running tests...${NC}"
cd tests/backend/
npm test
print_status "Tests passed"
cd ../..

# Build frontend
echo -e "\n${BLUE}Building frontend...${NC}"

# Build teacher dashboard
cd web-dashboard/teacher-dashboard/
print_info "Building teacher dashboard..."
npm run build
print_status "Teacher dashboard built"
cd ../..

# Build admin dashboard
cd web-dashboard/admin-dashboard/
print_info "Building admin dashboard..."
npm run build
print_status "Admin dashboard built"
cd ../..

# Create deployment package
echo -e "\n${BLUE}Creating deployment package...${NC}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DEPLOY_PACKAGE="deploy_${TIMESTAMP}.tar.gz"

tar -czf $DEPLOY_PACKAGE \
    --exclude='node_modules' \
    --exclude='.git' \
    --exclude='*.log' \
    --exclude='tests' \
    backend/ \
    web-dashboard/*/build/ \
    firmware/ \
    docs/

print_status "Deployment package created: $DEPLOY_PACKAGE"

# Upload to server
echo -e "\n${BLUE}Uploading to server...${NC}"
print_info "Connecting to $SERVER_HOST..."

scp $DEPLOY_PACKAGE ${SERVER_USER}@${SERVER_HOST}:/tmp/
print_status "Package uploaded"

# Deploy on server
echo -e "\n${BLUE}Deploying on server...${NC}"

ssh ${SERVER_USER}@${SERVER_HOST} << EOF
    set -e
    
    echo "Creating backup..."
    sudo tar -czf /var/backups/smart-classroom-watch-backup-${TIMESTAMP}.tar.gz -C ${APP_DIR} .
    
    echo "Extracting new version..."
    cd ${APP_DIR}
    sudo tar -xzf /tmp/${DEPLOY_PACKAGE}
    
    echo "Installing backend dependencies..."
    cd ${APP_DIR}/backend
    npm install --production
    
    echo "Running database migrations..."
    npm run migrate
    
    echo "Restarting services..."
    sudo systemctl restart smart-classroom-backend
    sudo systemctl restart nginx
    
    echo "Cleaning up..."
    rm /tmp/${DEPLOY_PACKAGE}
    
    echo "Checking service status..."
    sudo systemctl status smart-classroom-backend --no-pager
EOF

print_status "Deployment completed"

# Verify deployment
echo -e "\n${BLUE}Verifying deployment...${NC}"
sleep 5

HEALTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" https://${SERVER_HOST}/api/health)
if [ "$HEALTH_CHECK" = "200" ]; then
    print_status "Health check passed"
else
    print_error "Health check failed (HTTP $HEALTH_CHECK)"
    exit 1
fi

# Clean up local
rm $DEPLOY_PACKAGE
print_status "Local cleanup completed"

# Slack/Discord notification (optional)
if [ ! -z "$WEBHOOK_URL" ]; then
    curl -X POST $WEBHOOK_URL \
        -H 'Content-Type: application/json' \
        -d "{\"text\":\"✅ Smart Classroom Watch deployed to ${DEPLOY_ENV} (${TIMESTAMP})\"}"
fi

echo -e "\n${GREEN}================================${NC}"
echo -e "${GREEN}Deployment Successful! 🎉${NC}"
echo -e "${GREEN}================================${NC}\n"

echo -e "${YELLOW}Deployment Details:${NC}"
echo "Environment: $DEPLOY_ENV"
echo "Branch: $BRANCH"
echo "Timestamp: $TIMESTAMP"
echo "Server: $SERVER_HOST"
echo "Health Check: https://${SERVER_HOST}/api/health"

echo -e "\n${YELLOW}Next Steps:${NC}"
echo "1. Monitor logs: ${BLUE}ssh ${SERVER_USER}@${SERVER_HOST} 'sudo journalctl -u smart-classroom-backend -f'${NC}"
echo "2. Check metrics: https://${SERVER_HOST}/metrics"
echo "3. Review application: https://${SERVER_HOST}"

echo -e "\n${GREEN}Deployment complete! 🚀${NC}\n"
