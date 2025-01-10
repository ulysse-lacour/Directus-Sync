#!/bin/bash

#===========================================
# Scripts to start use directus-sync PULL function
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
    echo -e "\n\n${BOLD}${BLUE}=== $1 ===${NC}\n"
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
    local required_vars=(
      "NODE_VERSION"
      "PROJECT_NAME"
      "DIRECTUS_URL"
      "DIRECTUS_ADMIN_TOKEN"
    )
    local missing_vars=()

    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done

    if [ ${#missing_vars[@]} -ne 0 ]; then
        echo -e "\n"
        print_message "error" "Missing required environment variables:"
        for var in "${missing_vars[@]}"; do
            echo "  - $var"
        done
        echo -e "\n"
        exit 1
    fi
}

#-------------------------------------------
# Initialization
#-------------------------------------------

# Load configuration
check_env_file
validate_env_vars

#-------------------------------------------
# Functions
#-------------------------------------------

# Use the right node version
use_node_version() {
    print_header "Node Version"
    print_message "info" "Using right node version..."
    . ~/.nvm/nvm.sh
    nvm use ${NODE_VERSION}

    if [ $? -eq 0 ]; then
        print_message "success" "Node version set to ${NODE_VERSION}"
    else
        print_message "error" "Failed to set node version"
        exit 1
    fi
}

# Pull configuration from Directus
pull_config() {
    print_header "Pull configuration"
    print_message "info" "Pulling..."

    DIRECTUS_CONTAINER_NAME="${PROJECT_NAME}__directus"
    docker exec -i $DIRECTUS_CONTAINER_NAME npx directus-sync pull -d -u "${DIRECTUS_URL}" -t "${DIRECTUS_ADMIN_TOKEN}"

    if [ $? -eq 0 ]; then
        print_message "success" "Config successfully pulled"
    else
        print_message "error" "Failed to pull config"
        exit 1
    fi
}

# Main function to run all tasks
main() {
    use_node_version
    pull_config

    echo -e "\n\n"
    if [ $? -eq 0 ]; then
        echo -e "${BLUE}Config pulled there : ${BOLD}${YELLOW}./directus/directus-config${NC}\n"
    else
        print_message "error" "Failed to pull config..."
        exit 1
    fi
}

#-------------------------------------------
# Main
#-------------------------------------------
main

