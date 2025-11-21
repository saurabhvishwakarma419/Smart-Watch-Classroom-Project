#!/bin/bash

# Smart Classroom Watch - Backup Script
# Creates backups of database, files, and configurations

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
BACKUP_DIR=${BACKUP_DIR:-./backups}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="smart-classroom-backup-${TIMESTAMP}"
RETENTION_DAYS=${RETENTION_DAYS:-30}

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Smart Classroom Watch - Backup${NC}"
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

# Create backup directory
mkdir -p $BACKUP_DIR
print_status "Backup directory ready: $BACKUP_DIR"

# Create temporary directory for this backup
TEMP_BACKUP_DIR="/tmp/${BACKUP_NAME}"
mkdir -p $TEMP_BACKUP_DIR
print_info "Temporary backup directory: $TEMP_BACKUP_DIR"

# Backup MongoDB Database
echo -e "\n${BLUE}Backing up MongoDB...${NC}"
if command -v mongodump &> /dev/null; then
    print_info "Creating MongoDB dump..."
    mongodump \
        --uri="mongodb://localhost:27017/smart_classroom" \
        --out="${TEMP_BACKUP_DIR}/mongodb" \
        --gzip
    print_status "MongoDB backup completed"
else
    print_error "mongodump not found, skipping MongoDB backup"
fi

# Backup PostgreSQL Database (if using PostgreSQL)
echo -e "\n${BLUE}Backing up PostgreSQL...${NC}"
if command -v pg_dump &> /dev/null; then
    print_info "Creating PostgreSQL dump..."
    pg_dump \
        -U postgres \
        -d smart_classroom \
        -F c \
        -f "${TEMP_BACKUP_DIR}/postgresql_backup.dump"
    print_status "PostgreSQL backup completed"
else
    print_info "PostgreSQL not configured, skipping"
fi

# Backup Configuration Files
echo -e "\n${BLUE}Backing up configuration files...${NC}"
print_info "Copying configuration files..."

mkdir -p ${TEMP_BACKUP_DIR}/config

# Backend config
if [ -f "backend/.env" ]; then
    cp backend/.env ${TEMP_BACKUP_DIR}/config/backend.env
fi
if [ -f "backend/config/config.json" ]; then
    cp backend/config/config.json ${TEMP_BACKUP_DIR}/config/
fi

# Firmware config
if [ -f "firmware/include/config.h" ]; then
    cp firmware/include/config.h ${TEMP_BACKUP_DIR}/config/
fi

print_status "Configuration files backed up"

# Backup Uploaded Files
echo -e "\n${BLUE}Backing up uploaded files...${NC}"
if [ -d "backend/uploads" ]; then
    print_info "Copying uploaded files..."
    cp -r backend/uploads ${TEMP_BACKUP_DIR}/
    print_status "Uploaded files backed up"
else
    print_info "No uploads directory found"
fi

# Backup Logs
echo -e "\n${BLUE}Backing up logs...${NC}"
if [ -d "logs" ]; then
    print_info "Copying log files..."
    cp -r logs ${TEMP_BACKUP_DIR}/
    print_status "Logs backed up"
else
    print_info "No logs directory found"
fi

# Create backup metadata
echo -e "\n${BLUE}Creating backup metadata...${NC}"
cat > ${TEMP_BACKUP_DIR}/backup_info.txt << EOF
Smart Classroom Watch - Backup Information
==========================================
Backup Timestamp: ${TIMESTAMP}
Backup Date: $(date)
Hostname: $(hostname)
User: $(whoami)

Components Backed Up:
- MongoDB Database
- PostgreSQL Database (if configured)
- Configuration Files
- Uploaded Files
- Log Files

Backup Location: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz
EOF
print_status "Metadata created"

# Compress backup
echo -e "\n${BLUE}Compressing backup...${NC}"
print_info "Creating compressed archive..."
tar -czf ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz -C /tmp ${BACKUP_NAME}
BACKUP_SIZE=$(du -h ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz | cut -f1)
print_status "Backup compressed: ${BACKUP_SIZE}"

# Calculate checksum
echo -e "\n${BLUE}Calculating checksum...${NC}"
CHECKSUM=$(sha256sum ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz | cut -d' ' -f1)
echo "$CHECKSUM  ${BACKUP_NAME}.tar.gz" > ${BACKUP_DIR}/${BACKUP_NAME}.sha256
print_status "Checksum created: ${CHECKSUM:0:16}..."

# Clean up temporary files
print_info "Cleaning up temporary files..."
rm -rf $TEMP_BACKUP_DIR
print_status "Temporary files removed"

# Remove old backups
echo -e "\n${BLUE}Managing old backups...${NC}"
print_info "Removing backups older than ${RETENTION_DAYS} days..."
find $BACKUP_DIR -name "smart-classroom-backup-*.tar.gz" -type f -mtime +${RETENTION_DAYS} -delete
find $BACKUP_DIR -name "smart-classroom-backup-*.sha256" -type f -mtime +${RETENTION_DAYS} -delete
print_status "Old backups cleaned up"

# List recent backups
echo -e "\n${BLUE}Recent backups:${NC}"
ls -lh $BACKUP_DIR/smart-classroom-backup-*.tar.gz | tail -5

# Upload to cloud storage (optional)
if [ ! -z "$AWS_S3_BUCKET" ]; then
    echo -e "\n${BLUE}Uploading to AWS S3...${NC}"
    print_info "Uploading to s3://${AWS_S3_BUCKET}..."
    aws s3 cp ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz s3://${AWS_S3_BUCKET}/backups/
    aws s3 cp ${BACKUP_DIR}/${BACKUP_NAME}.sha256 s3://${AWS_S3_BUCKET}/backups/
    print_status "Backup uploaded to S3"
fi

# Send notification (optional)
if [ ! -z "$WEBHOOK_URL" ]; then
    curl -X POST $WEBHOOK_URL \
        -H 'Content-Type: application/json' \
        -d "{\"text\":\"✅ Smart Classroom Watch backup completed (${BACKUP_SIZE})\"}"
fi

# Final summary
echo -e "\n${GREEN}================================${NC}"
echo -e "${GREEN}Backup Complete! 🎉${NC}"
echo -e "${GREEN}================================${NC}\n"

echo -e "${YELLOW}Backup Details:${NC}"
echo "File: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
echo "Size: ${BACKUP_SIZE}"
echo "Checksum: ${CHECKSUM}"
echo "Timestamp: ${TIMESTAMP}"

echo -e "\n${YELLOW}To restore this backup:${NC}"
echo "${BLUE}tar -xzf ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz -C /tmp${NC}"
echo "${BLUE}mongorestore --gzip --dir=/tmp/${BACKUP_NAME}/mongodb${NC}"

echo -e "\n${GREEN}Backup successful! 💾${NC}\n"
