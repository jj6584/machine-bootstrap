#!/bin/bash

# Multi-OS Machine Bootstrap Script
# Automatically detects OS and runs appropriate installer

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            echo "debian"
        elif command -v dnf &> /dev/null; then
            echo "fedora"
        elif command -v yum &> /dev/null; then
            echo "rhel"
        elif command -v pacman &> /dev/null; then
            echo "arch"
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OS" == "Windows_NT" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

# Function to get script directory
get_script_dir() {
    cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
}

# Main execution
main() {
    echo -e "${CYAN}🚀 Starting Machine Bootstrap...${NC}"
    
    SCRIPT_DIR=$(get_script_dir)
    OS=$(detect_os)
    
    echo -e "${BLUE}📱 Detected OS: ${YELLOW}$OS${NC}"
    
    case $OS in
        "debian")
            echo -e "${GREEN}🐧 Running Debian/Ubuntu installer...${NC}"
            bash "$SCRIPT_DIR/linux/install-debian.sh"
            ;;
        "fedora"|"rhel")
            echo -e "${GREEN}🐧 Running Fedora/RHEL installer...${NC}"
            bash "$SCRIPT_DIR/linux/install-fedora.sh"
            ;;
        "arch")
            echo -e "${GREEN}🐧 Running Arch Linux installer...${NC}"
            bash "$SCRIPT_DIR/linux/install-arch.sh"
            ;;
        "macos")
            echo -e "${GREEN}🍎 Running macOS installer...${NC}"
            bash "$SCRIPT_DIR/macos/install-macos.sh"
            ;;
        "windows")
            echo -e "${GREEN}🪟 Running Windows installer...${NC}"
            if command -v powershell.exe &> /dev/null; then
                powershell.exe -ExecutionPolicy Bypass -File "$SCRIPT_DIR/windows/install-app.ps1"
            elif command -v pwsh &> /dev/null; then
                pwsh -ExecutionPolicy Bypass -File "$SCRIPT_DIR/windows/install-app.ps1"
            else
                echo -e "${RED}❌ PowerShell not found. Please run the Windows script manually.${NC}"
                echo -e "${YELLOW}Run: powershell.exe -ExecutionPolicy Bypass -File windows/install-app.ps1${NC}"
                exit 1
            fi
            ;;
        *)
            echo -e "${RED}❌ Unsupported OS: $OS${NC}"
            echo -e "${YELLOW}Supported: Debian/Ubuntu, Fedora/RHEL, Arch Linux, macOS, Windows${NC}"
            exit 1
            ;;
    esac
    
    echo -e "${GREEN}✅ Bootstrap complete!${NC}"
}

# Run main function
main "$@"
