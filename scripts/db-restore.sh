#!/bin/bash

#===========================================
# Directus Backup Restore Script
# This script restores both database and uploads from a backup
# Validates environment differences and provides clear user feedback
#===========================================

# Text colors and formatting for better UX
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#===========================================
# Utility Functions
#===========================================

# Print formatted message with emoji indicators
print_message() {
    local type=$1
    local message=$2
    case $type in
        "info") echo -e "${BLUE}ℹ️  ${message}${NC}" ;;
        "success") echo -e "${GREEN}✅ ${message}${NC}" ;;
        "error") echo -e "${RED}❌ ${message}${NC}" ;;
        "warning") echo -e "${YELLOW}⚠️  ${message}${NC}" ;;
    esac
}

# Print section header
print_header() {
    echo -e "\n${BOLD}${BLUE}=== $1 ===${NC}\n"
}

# Format timestamp to human-readable date
format_date() {
    local timestamp=$1
    if [[ $timestamp =~ ^([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})([0-9]{2}) ]]; then
        echo "${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]} ${BASH_REMATCH[4]}:${BASH_REMATCH[5]}"
    else
        echo "$timestamp"
    fi
}

#===========================================
# Environment Setup
#===========================================

# Check for environment file
if [ ! -f ".env" ]; then
    print_message "error" "Environment file not found: .env"
    exit 1
fi

print_header "Environment Check"
print_message "info" "Loading environment variables..."
set -a
source .env
set +a
print_message "success" "Environment loaded successfully"

# Set backup directory
BACKUP_DIR="./directus/backups"

#===========================================
# Backup Selection
#===========================================

print_header "Available Backups"

# Verify backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    print_message "error" "Backup directory not found"
    exit 1
fi

echo "Available backups:"
echo "-----------------"

# Initialize arrays for backup handling
TIMESTAMPS=()
FORMATTED_DATES=()

# Collect and validate complete backups
while read -r file; do
    if [[ $file =~ backup_([0-9]{8}_[0-9]{2}[0-9]{2})[0-9]*\.sql$ ]]; then
        timestamp="${BASH_REMATCH[1]}"
        if [ -f "${BACKUP_DIR}/backup_${timestamp}.sql" ] && \
           [ -f "${BACKUP_DIR}/uploads_${timestamp}.tar.gz" ]; then
            TIMESTAMPS+=("$timestamp")
            FORMATTED_DATES+=("$(format_date "$timestamp")")
        fi
    fi
done < <(ls -1 ${BACKUP_DIR}/backup_*.sql 2>/dev/null | sort -r)

# Check if any valid backups were found
if [ ${#TIMESTAMPS[@]} -eq 0 ]; then
    print_message "error" "No complete backups found"
    exit 1
fi

# Display available backups
for i in "${!TIMESTAMPS[@]}"; do
    echo "$((i+1))) ${FORMATTED_DATES[$i]}"
done

# Get user selection
echo
echo "Enter the number of the backup to restore (1-${#TIMESTAMPS[@]}):"
read -r selection

# Validate selection
if ! [[ "$selection" =~ ^[0-9]+$ ]] || \
   [ "$selection" -lt 1 ] || \
   [ "$selection" -gt "${#TIMESTAMPS[@]}" ]; then
    print_message "error" "Invalid selection"
    exit 1
fi

# Get selected timestamp and confirm
SELECTED_TIMESTAMP="${TIMESTAMPS[$((selection-1))]}"
print_message "success" "Selected backup from: $(format_date "$SELECTED_TIMESTAMP")"

#===========================================
# Restore Confirmation
#===========================================

print_header "Restore Confirmation"
print_message "warning" "This will overwrite both database and uploads data. Continue? (y/n)"
read -r confirm
if [[ ! "$confirm" =~ ^[yYnN]$ ]]; then
    print_message "error" "Invalid input. Please answer y or n"
    exit 1
fi

if [[ "$confirm" =~ ^[nN]$ ]]; then
    print_message "info" "Restoration cancelled"
    exit 0
fi

#===========================================
# Database Restore
#===========================================

print_header "Starting Restore Process"
print_message "info" "Starting restore process for project: ${PROJECT_NAME}"

# Track execution time
RESTORE_START_TIME=$(date +%s)

# Terminate existing connections (quietly)
docker exec -i "${PROJECT_NAME}__database" psql \
    -h "${DB_HOST}" \
    -p "${DB_PORT}" \
    -U "${DB_USER}" \-d "postgres" \
    -q \
    << EOF > /dev/null
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = '${DB_NAME}'
AND pid <> pg_backend_pid();
EOF

# Drop and recreate the database (quietly)
docker exec -i "${PROJECT_NAME}__database" psql \
    -h "${DB_HOST}" \
    -p "${DB_PORT}" \
    -U "${DB_USER}" \
    -d "postgres" \
    -q \
    << EOF > /dev/null
DROP DATABASE IF EXISTS "${DB_NAME}";
CREATE DATABASE "${DB_NAME}" WITH OWNER = "${DB_USER}";
EOF

# Create a temporary file for logging
temp_log=$(mktemp)

# Restore the database based on backup format
if [[ -f "${BACKUP_DIR}/backup_${SELECTED_TIMESTAMP}.dump" ]]; then
    # Custom format backup
    docker exec -i "${PROJECT_NAME}__database" pg_restore \
        -h "${DB_HOST}" \
        -p "${DB_PORT}" \
        -U "${DB_USER}" \
        -d "${DB_NAME}" \
        --no-owner \
        --no-acl \
        --clean \
        --if-exists \
        --disable-triggers \
        --single-transaction \
        "/backups/backup_${SELECTED_TIMESTAMP}.dump" > "$temp_log" 2>&1
else
    # Plain SQL backup
    docker exec -i "${PROJECT_NAME}__database" psql \
        -h "${DB_HOST}" \
        -p "${DB_PORT}" \
        -U "${DB_USER}" \
        -d "${DB_NAME}" \
        -q < "${BACKUP_DIR}/backup_${SELECTED_TIMESTAMP}.sql" > "$temp_log" 2>&1
fi

if [ $? -ne 0 ]; then
    print_message "error" "Database restore failed"
    cat "$temp_log"
    rm "$temp_log"
    exit 1
fi

rm "$temp_log"
print_message "success" "Database restored successfully"

#===========================================
# Uploads Restore
#===========================================

print_header "Uploads Restore"
print_message "info" "Restoring uploads..."

rm -rf ./directus/uploads/* 2>/dev/null
tar -xzf "${BACKUP_DIR}/uploads_${SELECTED_TIMESTAMP}.tar.gz" -C ./directus/uploads/

if [ $? -ne 0 ]; then
    print_message "error" "Uploads restore failed"
    exit 1
fi

print_message "success" "Uploads restored successfully"

#===========================================
# Restore Complete
#===========================================

# Calculate total duration
RESTORE_END_TIME=$(date +%s)
TOTAL_DURATION=$((RESTORE_END_TIME - RESTORE_START_TIME))

print_header "Time Summary"
print_message "info" "Total restore duration: ${TOTAL_DURATION} seconds"

# Then the existing completion messages
print_header "Restore Complete"
print_message "success" "Full restore completed successfully"
