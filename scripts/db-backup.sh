#!/bin/bash

#===========================================
# Directus Backup Script
# Creates a complete backup of Directus database and uploads
# Version: 1.0
#===========================================

#-------------------------------------------
# Color Configuration and Utility Functions
#-------------------------------------------

# Text formatting
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print formatted message with emoji indicators
print_message() {
    local type=$1
    local message=$2
    case $type in
        "info") echo -e "${BLUE}ℹ️  ${message}${NC}" ;;
        "success") echo -e "${GREEN}✅ ${message}${NC}" ;;
        "error") echo -e "${RED}❌ ${message}${NC}" ;;
        "warning") echo -e "${YELLOW}⚠️  ${message}${NC}" ;;
        *) echo -e "$message" ;;
    esac
}

# Print section header with clear separation
print_header() {
    echo -e "\n${BOLD}${BLUE}=== $1 ===${NC}\n"
}

#-------------------------------------------
# Environment Configuration
#-------------------------------------------

# Load and validate environment configuration
check_env_file() {
    print_header "Environment Check"
    if [ ! -f ".env" ]; then
        print_message "error" "Environment file not found: .env"
        exit 1
    fi
    print_message "info" "Loading environment variables..."
    set -a
    source .env
    set +a
    print_message "success" "Environment loaded successfully"
}

# Verify all required variables are set
validate_env_vars() {
    local required_vars=("PROJECT_NAME" "DB_HOST" "DB_PORT" "DB_USER" "DB_NAME" "DB_PWD")
    local missing_vars=()

    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done

    if [ ${#missing_vars[@]} -ne 0 ]; then
        print_message "error" "Missing required environment variables:"
        for var in "${missing_vars[@]}"; do
            echo "  - $var"
        done
        exit 1
    fi
}

#-------------------------------------------
# Initialization
#-------------------------------------------

# Load configuration
check_env_file
validate_env_vars

# Set backup paths and timestamps
TIMESTAMP=$(date +%Y%m%d_%H%M)
BACKUP_DIR="./directus/backups"
DB_CONTAINER_NAME="${PROJECT_NAME}__database"

#-------------------------------------------
# Database Backup Functions
#-------------------------------------------

# Create database backup
backup_database() {
    print_header "Database Backup"
    print_message "info" "Creating backup directories..."

    # Ensure backup directory exists
    mkdir -p "${BACKUP_DIR}"

    # Create database dump with safety flags
    print_message "info" "Creating database dump..."
    docker exec -i $DB_CONTAINER_NAME pg_dump \
        -h "${DB_HOST}" \
        -p "${DB_PORT}" \
        -U "${DB_USER}" \
        -d "${DB_NAME}" \
        --clean \
        --if-exists \
        -F p > "${BACKUP_DIR}/backup_${TIMESTAMP}.sql"

    if [ $? -eq 0 ]; then
        print_message "success" "Database backup completed: backup_${TIMESTAMP}.sql"
        # Show backup size for verification
        local size=$(du -h "${BACKUP_DIR}/backup_${TIMESTAMP}.sql" | cut -f1)
        print_message "info" "Backup size: ${size}"
    else
        print_message "error" "Database backup failed"
        exit 1
    fi
}

#-------------------------------------------
# Uploads Backup Functions
#-------------------------------------------

# Backup Directus uploads directory
backup_uploads() {
    print_header "Uploads Backup"
    print_message "info" "Creating uploads backup..."

    mkdir -p ${BACKUP_DIR}

    # Verify uploads directory exists and contains files
    if [ ! -d "./directus/uploads" ] || [ -z "$(ls -A ./directus/uploads 2>/dev/null)" ]; then
        print_message "warning" "Uploads directory is empty or doesn't exist"
        print_message "info" "Creating empty uploads backup for consistency"
        mkdir -p "./directus/uploads"
    fi

    # Create compressed archive of uploads
    tar -czf "${BACKUP_DIR}/uploads_${TIMESTAMP}.tar.gz" -C ./directus/uploads . || {
        print_message "error" "Uploads backup failed"
        exit 1
    }

    # Show backup size for verification
    local size=$(du -h "${BACKUP_DIR}/uploads_${TIMESTAMP}.tar.gz" | cut -f1)
    print_message "success" "Uploads backup completed: uploads_${TIMESTAMP}.tar.gz"
    print_message "info" "Backup size: ${size}"
}

#-------------------------------------------
# Main Backup Process
#-------------------------------------------

# Execute complete backup process
backup_all() {
    print_header "Starting Backup Process"
    print_message "info" "Starting full backup for project: ${PROJECT_NAME}"

    # Track execution time
    local start_time=$(date +%s)

    # Execute backup operations
    backup_database
    backup_uploads

    # Calculate and display execution summary
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    # Display backup summary
    print_header "Backup Summary"
    print_message "success" "Full backup completed successfully"
    print_message "info" "Total duration: ${duration} seconds"
    print_message "info" "Database backup: ${BACKUP_DIR}/backup_${TIMESTAMP}.sql"
    print_message "info" "Uploads backup: ${BACKUP_DIR}/uploads_${TIMESTAMP}.tar.gz"
}

#-------------------------------------------
# Main
#-------------------------------------------
main() {
    backup_all

    if [ $? -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

main
