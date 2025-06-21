#!/bin/bash

# Enhanced Machine Bootstrap installer with all improvements
# This replaces your current install.sh with enhanced features

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Script metadata
SCRIPT_VERSION="2.0.0"
SCRIPT_NAME="Machine Bootstrap"
GITHUB_USER="YOUR_USERNAME"
REPO_NAME="machine-bootstrap"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${REPO_NAME}/${BRANCH}"

# Configuration
CONFIG_FILE="${HOME}/.config/machine-bootstrap/config.yml"
LOG_FILE="/tmp/machine-bootstrap-$(date +%Y%m%d-%H%M%S).log"
BACKUP_DIR="$HOME/.machine-bootstrap-backups/$(date +%Y%m%d-%H%M%S)"

# Default settings
DRY_RUN=false
CREATE_BACKUP=false
QUIET=false
FORCE_INSTALL=false
SKIP_SNAP=false
SKIP_FLATPAK=false
PACKAGE_CATEGORY=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Progress tracking
TOTAL_STEPS=0
CURRENT_STEP=0
START_TIME=$(date +%s)

# Logging setup
exec 1> >(tee -a "$LOG_FILE")
exec 2> >(tee -a "$LOG_FILE" >&2)

# Error handling
handle_error() {
    local exit_code=$?
    local line_number=$1
    echo -e "${RED}❌ Error on line $line_number. Exit code: $exit_code${NC}" >&2
    echo -e "${YELLOW}Check log file: $LOG_FILE${NC}" >&2
    
    # Offer rollback if backup exists
    if [ -d "$BACKUP_DIR" ]; then
        echo -e "${BLUE}Backup available at: $BACKUP_DIR${NC}"
        read -p "Would you like to rollback? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rollback_changes
        fi
    fi
    
    exit $exit_code
}

trap 'handle_error $LINENO' ERR

# Help system
show_help() {
    cat << EOF
${SCRIPT_NAME} v${SCRIPT_VERSION} - Cross-platform development environment setup

USAGE:
    bash <(curl -fsSL ${BASE_URL}/install.sh) [OPTIONS] [CATEGORY]

CATEGORIES:
    basic       Essential tools and applications
    remote      Remote work applications (Teams, Zoom, etc.)
    dev         Developer tools and environments
    all         Install everything

OPTIONS:
    -h, --help          Show this help message
    -v, --version       Show version information
    -c, --config FILE   Use custom configuration file
    -d, --dry-run       Show what would be installed without installing
    -b, --backup        Create backup before installation
    -q, --quiet         Minimal output
    -f, --force         Force installation even if packages exist
    --no-snap          Skip snap package installation
    --no-flatpak       Skip flatpak package installation
    --check-updates    Check for script updates

EXAMPLES:
    # Basic installation
    curl -fsSL ${BASE_URL}/install.sh | bash

    # Install specific category
    curl -fsSL ${BASE_URL}/install.sh | bash -s basic
    
    # Dry run with backup
    curl -fsSL ${BASE_URL}/install.sh | bash -s -- --dry-run --backup dev

CONFIGURATION:
    Default config: ~/.config/machine-bootstrap/config.yml
    Example: ${BASE_URL}/config.yml.example

For more information: https://github.com/${GITHUB_USER}/${REPO_NAME}
EOF
}

show_version() {
    echo "${SCRIPT_NAME} v${SCRIPT_VERSION}"
    echo "https://github.com/${GITHUB_USER}/${REPO_NAME}"
}

# Progress bar
show_progress() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((current * width / total))
    local remaining=$((width - completed))
    
    printf "\r["
    printf "%${completed}s" | tr ' ' '█'
    printf "%${remaining}s" | tr ' ' '░'
    printf "] %d%% (%d/%d)" $percentage $current $total
}

step() {
    local description=$1
    CURRENT_STEP=$((CURRENT_STEP + 1))
    
    if [ "$QUIET" = false ]; then
        echo -e "\n${CYAN}[$CURRENT_STEP/$TOTAL_STEPS] $description${NC}"
        show_progress $CURRENT_STEP $TOTAL_STEPS
    fi
}

# Network check
check_network() {
    step "Checking network connectivity"
    if ! ping -c 1 google.com &> /dev/null; then
        echo -e "${RED}❌ No internet connection detected${NC}"
        exit 1
    fi
}

# OS Detection
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

# Backup system
create_backup() {
    if [ "$CREATE_BACKUP" = true ]; then
        step "Creating system backup"
        mkdir -p "$BACKUP_DIR"
        
        # Backup config files
        for file in ".bashrc" ".zshrc" ".gitconfig" ".vimrc"; do
            [ -f "$HOME/$file" ] && cp "$HOME/$file" "$BACKUP_DIR/" || true
        done
        
        # Save package list
        local os=$(detect_os)
        case $os in
            "debian")
                dpkg --get-selections > "$BACKUP_DIR/installed-packages.txt"
                ;;
            "fedora")
                dnf list installed > "$BACKUP_DIR/installed-packages.txt"
                ;;
            "arch")
                pacman -Q > "$BACKUP_DIR/installed-packages.txt"
                ;;
        esac
        
        echo -e "${GREEN}✅ Backup created at: $BACKUP_DIR${NC}"
    fi
}

# Update checker
check_for_updates() {
    step "Checking for updates"
    if command -v jq &> /dev/null; then
        local latest_version=$(curl -s "https://api.github.com/repos/${GITHUB_USER}/${REPO_NAME}/releases/latest" | jq -r '.tag_name' | sed 's/^v//')
        
        if [ "$latest_version" != "$SCRIPT_VERSION" ] && [ "$latest_version" != "null" ]; then
            echo -e "${YELLOW}📱 New version available: $latest_version (current: $SCRIPT_VERSION)${NC}"
            echo -e "${BLUE}Visit: https://github.com/${GITHUB_USER}/${REPO_NAME}/releases${NC}"
        fi
    fi
}

# Enhanced download function
download_and_run() {
    local script_path=$1
    shift
    local script_name=$(basename "$script_path")
    
    step "Downloading $script_name"
    
    local temp_file=$(mktemp)
    
    if curl -fsSL "$BASE_URL/$script_path" -o "$temp_file"; then
        chmod +x "$temp_file"
        
        if [ "$DRY_RUN" = true ]; then
            echo -e "${BLUE}[DRY RUN] Would execute: $script_name $*${NC}"
        else
            step "Executing $script_name"
            bash "$temp_file" "$@"
        fi
        
        rm -f "$temp_file"
    else
        echo -e "${RED}❌ Failed to download $script_name${NC}"
        exit 1
    fi
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help) show_help; exit 0 ;;
            -v|--version) show_version; exit 0 ;;
            -d|--dry-run) DRY_RUN=true; shift ;;
            -b|--backup) CREATE_BACKUP=true; shift ;;
            -q|--quiet) QUIET=true; shift ;;
            -f|--force) FORCE_INSTALL=true; shift ;;
            --no-snap) SKIP_SNAP=true; shift ;;
            --no-flatpak) SKIP_FLATPAK=true; shift ;;
            --check-updates) check_for_updates; exit 0 ;;
            basic|remote|dev|all) PACKAGE_CATEGORY="$1"; shift ;;
            *) echo "Unknown option: $1"; show_help; exit 1 ;;
        esac
    done
}

# Main execution
main() {
    parse_args "$@"
    
    if [ "$QUIET" = false ]; then
        echo -e "${CYAN}🚀 ${SCRIPT_NAME} v${SCRIPT_VERSION}${NC}"
        echo -e "${BLUE}Repository: https://github.com/${GITHUB_USER}/${REPO_NAME}${NC}"
        echo ""
    fi
    
    # Calculate total steps
    TOTAL_STEPS=6
    [ "$CREATE_BACKUP" = true ] && TOTAL_STEPS=$((TOTAL_STEPS + 1))
    
    check_network
    check_for_updates
    create_backup
    
    local os=$(detect_os)
    step "Detected OS: $os"
    
    case $os in
        "debian")
            download_and_run "linux/install-debian.sh" "$PACKAGE_CATEGORY"
            ;;
        "fedora")
            download_and_run "linux/install-fedora.sh" "$PACKAGE_CATEGORY"
            ;;
        "arch")
            download_and_run "linux/install-arch.sh" "$PACKAGE_CATEGORY"
            ;;
        "macos")
            download_and_run "macos/install-macos.sh" "$PACKAGE_CATEGORY"
            ;;
        "windows")
            echo -e "${CYAN}🪟 Windows detected!${NC}"
            echo -e "${YELLOW}Please run this PowerShell command:${NC}"
            echo "irm $BASE_URL/install.ps1 | iex"
            ;;
        *)
            echo -e "${RED}❌ Unsupported OS: $os${NC}"
            exit 1
            ;;
    esac
    
    step "Installation complete"
    
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))
    
    if [ "$QUIET" = false ]; then
        echo ""
        echo -e "${GREEN}✅ Bootstrap complete! (${duration}s)${NC}"
        echo -e "${YELLOW}Log file: $LOG_FILE${NC}"
        [ "$CREATE_BACKUP" = true ] && echo -e "${YELLOW}Backup: $BACKUP_DIR${NC}"
        echo -e "${BLUE}⭐ Star the repo: https://github.com/${GITHUB_USER}/${REPO_NAME}${NC}"
    fi
}

main "$@"
