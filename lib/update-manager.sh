#!/bin/bash

# Update & Maintenance System
# Handles automatic updates and system maintenance

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
GITHUB_USER="jj6584"
REPO_NAME="machine-bootstrap"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${REPO_NAME}/${BRANCH}"
VERSION_CHECK_URL="https://api.github.com/repos/${GITHUB_USER}/${REPO_NAME}/releases/latest"
UPDATE_CHECK_INTERVAL=86400  # 24 hours in seconds
UPDATE_CACHE_FILE="$HOME/.cache/machine-bootstrap/last-update-check"
CURRENT_VERSION="2.0.0"

# Create cache directory
mkdir -p "$(dirname "$UPDATE_CACHE_FILE")"

# Check if update check is needed
should_check_for_updates() {
    if [ ! -f "$UPDATE_CACHE_FILE" ]; then
        return 0  # First run, should check
    fi
    
    local last_check=$(cat "$UPDATE_CACHE_FILE" 2>/dev/null || echo "0")
    local current_time=$(date +%s)
    local time_diff=$((current_time - last_check))
    
    if [ $time_diff -gt $UPDATE_CHECK_INTERVAL ]; then
        return 0  # Time to check
    else
        return 1  # Too soon
    fi
}

# Get latest version from GitHub
get_latest_version() {
    if command -v jq &> /dev/null; then
        curl -s "$VERSION_CHECK_URL" | jq -r '.tag_name' | sed 's/^v//'
    elif command -v python3 &> /dev/null; then
        curl -s "$VERSION_CHECK_URL" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data['tag_name'].lstrip('v'))
except:
    print('unknown')
"
    else
        echo "unknown"
    fi
}

# Compare version strings
version_greater_than() {
    local version1=$1
    local version2=$2
    
    # Simple version comparison for semantic versioning
    printf '%s\n%s\n' "$version1" "$version2" | sort -V | head -n1 | grep -q "^$version2$"
}

# Check for updates
check_for_updates() {
    echo -e "${BLUE}🔍 Checking for updates...${NC}"
    
    local latest_version=$(get_latest_version)
    
    if [ "$latest_version" = "unknown" ]; then
        echo -e "${YELLOW}⚠️ Could not check for updates (install 'jq' or 'python3' for update checking)${NC}"
        return 1
    fi
    
    # Update cache
    date +%s > "$UPDATE_CACHE_FILE"
    
    if [ "$latest_version" != "$CURRENT_VERSION" ] && version_greater_than "$latest_version" "$CURRENT_VERSION"; then
        echo -e "${YELLOW}📱 New version available: $latest_version (current: $CURRENT_VERSION)${NC}"
        echo -e "${BLUE}Release notes: https://github.com/${GITHUB_USER}/${REPO_NAME}/releases/tag/v${latest_version}${NC}"
        
        read -p "Would you like to update now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            update_script
        else
            echo -e "${YELLOW}You can update later by running: --update${NC}"
        fi
    else
        echo -e "${GREEN}✅ You're running the latest version ($CURRENT_VERSION)${NC}"
    fi
}

# Auto-check for updates (non-interactive)
auto_check_updates() {
    if should_check_for_updates; then
        local latest_version=$(get_latest_version)
        
        if [ "$latest_version" != "unknown" ] && [ "$latest_version" != "$CURRENT_VERSION" ]; then
            if version_greater_than "$latest_version" "$CURRENT_VERSION"; then
                echo -e "${YELLOW}💡 Update available: v$latest_version (run with --check-updates to update)${NC}"
            fi
        fi
        
        # Update cache
        date +%s > "$UPDATE_CACHE_FILE"
    fi
}

# Update script to latest version
update_script() {
    echo -e "${BLUE}📥 Downloading latest version...${NC}"
    
    local temp_file=$(mktemp)
    local install_url="$BASE_URL/install.sh"
    
    if curl -fsSL "$install_url" -o "$temp_file"; then
        chmod +x "$temp_file"
        echo -e "${GREEN}✅ Downloaded latest version${NC}"
        echo -e "${BLUE}🔄 Restarting with new version...${NC}"
        
        # Replace current script and restart
        exec "$temp_file" "$@"
    else
        echo -e "${RED}❌ Failed to download update${NC}"
        rm -f "$temp_file"
        return 1
    fi
}

# Update package lists/repositories
update_package_sources() {
    echo -e "${BLUE}🔄 Updating package sources...${NC}"
    
    case $(detect_os) in
        "debian")
            echo -e "${YELLOW}Updating APT repositories...${NC}"
            sudo apt update
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✅ APT repositories updated${NC}"
            else
                echo -e "${RED}❌ Failed to update APT repositories${NC}"
                return 1
            fi
            ;;
        "fedora")
            echo -e "${YELLOW}Updating DNF repositories...${NC}"
            sudo dnf check-update
            echo -e "${GREEN}✅ DNF repositories updated${NC}"
            ;;
        "arch")
            echo -e "${YELLOW}Updating Pacman repositories...${NC}"
            sudo pacman -Sy
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✅ Pacman repositories updated${NC}"
            else
                echo -e "${RED}❌ Failed to update Pacman repositories${NC}"
                return 1
            fi
            ;;
        "macos")
            echo -e "${YELLOW}Updating Homebrew...${NC}"
            if command -v brew &> /dev/null; then
                brew update
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}✅ Homebrew updated${NC}"
                else
                    echo -e "${RED}❌ Failed to update Homebrew${NC}"
                    return 1
                fi
            else
                echo -e "${YELLOW}Homebrew not installed${NC}"
            fi
            ;;
        "windows")
            echo -e "${YELLOW}Please update Chocolatey manually: choco upgrade chocolatey${NC}"
            ;;
    esac
    
    return 0
}

# Upgrade installed packages
upgrade_packages() {
    echo -e "${BLUE}⬆️ Upgrading installed packages...${NC}"
    
    case $(detect_os) in
        "debian")
            echo -e "${YELLOW}Upgrading APT packages...${NC}"
            sudo apt upgrade -y
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✅ APT packages upgraded${NC}"
            else
                echo -e "${RED}❌ Some packages failed to upgrade${NC}"
            fi
            ;;
        "fedora")
            echo -e "${YELLOW}Upgrading DNF packages...${NC}"
            sudo dnf upgrade -y
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✅ DNF packages upgraded${NC}"
            else
                echo -e "${RED}❌ Some packages failed to upgrade${NC}"
            fi
            ;;
        "arch")
            echo -e "${YELLOW}Upgrading Pacman packages...${NC}"
            sudo pacman -Syu --noconfirm
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✅ Pacman packages upgraded${NC}"
            else
                echo -e "${RED}❌ Some packages failed to upgrade${NC}"
            fi
            ;;
        "macos")
            echo -e "${YELLOW}Upgrading Homebrew packages...${NC}"
            if command -v brew &> /dev/null; then
                brew upgrade
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}✅ Homebrew packages upgraded${NC}"
                else
                    echo -e "${RED}❌ Some packages failed to upgrade${NC}"
                fi
            fi
            ;;
        "windows")
            echo -e "${YELLOW}Please upgrade packages manually: choco upgrade all${NC}"
            ;;
    esac
}

# Clean up package caches
cleanup_packages() {
    echo -e "${BLUE}🧹 Cleaning up package caches...${NC}"
    
    case $(detect_os) in
        "debian")
            sudo apt autoremove -y
            sudo apt autoclean
            echo -e "${GREEN}✅ APT cache cleaned${NC}"
            ;;
        "fedora")
            sudo dnf autoremove -y
            sudo dnf clean all
            echo -e "${GREEN}✅ DNF cache cleaned${NC}"
            ;;
        "arch")
            sudo pacman -Sc --noconfirm
            echo -e "${GREEN}✅ Pacman cache cleaned${NC}"
            ;;
        "macos")
            if command -v brew &> /dev/null; then
                brew cleanup
                echo -e "${GREEN}✅ Homebrew cache cleaned${NC}"
            fi
            ;;
        "windows")
            echo -e "${YELLOW}Please clean cache manually: choco cache clean${NC}"
            ;;
    esac
}

# System maintenance
run_maintenance() {
    echo -e "${CYAN}🔧 Running system maintenance...${NC}"
    echo ""
    
    local maintenance_tasks=(
        "update_package_sources"
        "upgrade_packages" 
        "cleanup_packages"
    )
    
    for task in "${maintenance_tasks[@]}"; do
        echo -e "${CYAN}Running: $task${NC}"
        if $task; then
            echo -e "${GREEN}✅ $task completed${NC}"
        else
            echo -e "${YELLOW}⚠️ $task completed with warnings${NC}"
        fi
        echo ""
    done
    
    echo -e "${GREEN}✅ System maintenance completed${NC}"
}

# OS detection helper
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            echo "debian"
        elif command -v dnf &> /dev/null; then
            echo "fedora"
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

# Main update function
main_update() {
    local action=${1:-"check"}
    
    case $action in
        "check")
            check_for_updates
            ;;
        "auto-check")
            auto_check_updates
            ;;
        "update")
            update_script
            ;;
        "maintenance")
            run_maintenance
            ;;
        "sources")
            update_package_sources
            ;;
        "upgrade")
            upgrade_packages
            ;;
        "cleanup")
            cleanup_packages
            ;;
        *)
            echo "Usage: $0 {check|auto-check|update|maintenance|sources|upgrade|cleanup}"
            exit 1
            ;;
    esac
}

# Export functions
export -f check_for_updates
export -f auto_check_updates
export -f update_script
export -f run_maintenance

# If script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_update "$@"
fi
