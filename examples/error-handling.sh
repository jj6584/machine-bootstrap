#!/bin/bash

# Enhanced error handling and logging example
set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Logging setup
LOG_FILE="/tmp/machine-bootstrap-$(date +%Y%m%d-%H%M%S).log"
exec 1> >(tee -a "$LOG_FILE")
exec 2> >(tee -a "$LOG_FILE" >&2)

# Error handling function
handle_error() {
    local exit_code=$?
    local line_number=$1
    echo -e "${RED}❌ Error on line $line_number. Exit code: $exit_code${NC}" >&2
    echo -e "${YELLOW}Check log file: $LOG_FILE${NC}" >&2
    exit $exit_code
}

trap 'handle_error $LINENO' ERR

# Network connectivity check
check_network() {
    echo "🌐 Checking network connectivity..."
    if ! ping -c 1 google.com &> /dev/null; then
        echo -e "${RED}❌ No internet connection detected${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Network connectivity OK${NC}"
}

# Package installation with retry logic
install_package_with_retry() {
    local package=$1
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo "Installing $package (attempt $attempt/$max_attempts)..."
        if sudo apt install -y "$package"; then
            echo -e "${GREEN}✅ Successfully installed $package${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠️ Failed to install $package (attempt $attempt)${NC}"
            attempt=$((attempt + 1))
            sleep 2
        fi
    done
    
    echo -e "${RED}❌ Failed to install $package after $max_attempts attempts${NC}"
    return 1
}
