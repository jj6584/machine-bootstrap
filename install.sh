#!/bin/bash

# Enhanced Machine Bootstrap installer with all improvements
# This replaces your current install.sh with enhanced features

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Script metadata
SCRIPT_VERSION="2.0.0"
SCRIPT_NAME="Machine Bootstrap"
GITHUB_USER="jj6584"
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
SKIP_SYSTEM_CHECK=false
SKIP_SECURITY_CHECK=false
PARALLEL_INSTALL=false
PACKAGE_CATEGORY=""
TIMEOUT=300
LOG_LEVEL="info"
ENABLE_GUI=false
ENABLE_DOCKER=false
ENABLE_PLUGINS=false
ENABLE_ANALYTICS=false
ENABLE_CLOUD=false
ENABLE_GPU=false
AUTO_GPU=false

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
    local error_message="Error on line $line_number. Exit code: $exit_code"
    
    echo -e "${RED}❌ $error_message${NC}" >&2
    echo -e "${YELLOW}Check log file: $LOG_FILE${NC}" >&2
    
    # Track error in analytics
    if [ "$ENABLE_ANALYTICS" = true ] && command -v track_error &> /dev/null; then
        track_error "installation_error" "$error_message" "line:$line_number"
    fi
    
    # Execute error hooks
    if [ "$ENABLE_PLUGINS" = true ] && command -v execute_hook &> /dev/null; then
        execute_hook "on_error" "$error_message" "$line_number"
    fi
    
    # Show GUI error dialog
    if [ "$ENABLE_GUI" = true ] && command -v show_error_gui &> /dev/null; then
        show_error_gui "Installation failed" "$error_message"
    fi
    
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
    -h, --help              Show this help message
    -v, --version           Show version information
    -c, --config FILE       Use custom configuration file
    -d, --dry-run           Show what would be installed without installing
    -b, --backup            Create backup before installation
    -q, --quiet             Minimal output
    -f, --force             Force installation even if packages exist
    --no-snap              Skip snap package installation
    --no-flatpak           Skip flatpak package installation
    --check-updates        Check for script updates
    --system-check         Run system requirements check only
    --security-check       Run security checks only
    --skip-checks          Skip all system and security checks
    --parallel             Enable parallel package installation
    --timeout SECONDS      Set download timeout (default: 300)
    --log-level LEVEL      Set log level (debug, info, warn, error)
    --gui                  Use graphical interface (requires zenity/dialog)
    --docker               Include Docker containerization setup
    --plugins              Enable plugin system support
    --analytics            Enable anonymous usage analytics
    --cloud                Include cloud integration tools
    --gpu                  Setup GPU drivers and gaming environment
    --auto-gpu             Auto-detect and install GPU drivers

EXAMPLES:
    # Basic installation
    curl -fsSL ${BASE_URL}/install.sh | bash

    # Install specific category
    curl -fsSL ${BASE_URL}/install.sh | bash -s basic
    
    # Dry run with backup and system checks
    curl -fsSL ${BASE_URL}/install.sh | bash -s -- --dry-run --backup --system-check dev

    # Force install with parallel processing
    curl -fsSL ${BASE_URL}/install.sh | bash -s -- --force --parallel all

    # Quick install without checks (not recommended)
    curl -fsSL ${BASE_URL}/install.sh | bash -s -- --skip-checks --quiet basic

MAINTENANCE:
    # Check for updates
    curl -fsSL ${BASE_URL}/install.sh | bash -s -- --check-updates
    
    # Run system maintenance
    curl -fsSL ${BASE_URL}/lib/update-manager.sh | bash -s maintenance
    
    # Security audit
    curl -fsSL ${BASE_URL}/install.sh | bash -s -- --security-check

CONFIGURATION:
    Default config: ~/.config/machine-bootstrap/config.yml
    Example: ${BASE_URL}/config.yml.example

SYSTEM REQUIREMENTS:
    - Internet connection
    - 2GB free disk space (minimum)
    - 1GB RAM (minimum)
    - Package manager (apt, dnf, pacman, brew, choco)
    - curl or wget

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

# Enhanced download function with security
download_and_run() {
    local script_path=$1
    shift
    local script_name=$(basename "$script_path")
    
    step "Downloading $script_name"
    
    local temp_file=$(mktemp)
    
    # Source security module if available
    if [ -f "lib/security.sh" ]; then
        source lib/security.sh
    fi
    
    if curl -fsSL "$BASE_URL/$script_path" -o "$temp_file"; then
        chmod +x "$temp_file"
        
        # Verify download if security module is loaded
        if command -v verify_download &> /dev/null && [ -n "$SCRIPT_HASH" ]; then
            if ! verify_download "$temp_file" "$SCRIPT_HASH"; then
                echo -e "${RED}❌ Script verification failed${NC}"
                rm -f "$temp_file"
                exit 1
            fi
        fi
        
        if [ "$DRY_RUN" = true ]; then
            echo -e "${BLUE}[DRY RUN] Would execute: $script_name $*${NC}"
            
            # Show what packages would be installed
            echo -e "${CYAN}Packages that would be installed:${NC}"
            case $(detect_os) in
                "debian")
                    if grep -q "packages_basic" "$temp_file"; then
                        echo -e "${YELLOW}Basic packages: curl, wget, git, vim, firefox, vlc, snapd${NC}"
                    fi
                    if [[ "$*" == *"dev"* ]]; then
                        echo -e "${YELLOW}Dev packages: nodejs, npm, python3, docker, build-essential${NC}"
                    fi
                    ;;
                "windows")
                    echo -e "${YELLOW}Windows packages would be installed via PowerShell${NC}"
                    ;;
            esac
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

# Download and source a module
download_and_source() {
    local script_path=$1
    local script_name=$(basename "$script_path")
    local temp_file=$(mktemp)
    
    if curl -fsSL "$BASE_URL/$script_path" -o "$temp_file" 2>/dev/null; then
        chmod +x "$temp_file"
        if source "$temp_file"; then
            rm -f "$temp_file"
            return 0
        else
            echo -e "${RED}❌ Failed to source $script_name${NC}"
            rm -f "$temp_file"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️  Failed to download $script_name${NC}"
        rm -f "$temp_file"
        return 1
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
            --system-check) 
                if [ -f "lib/system-check.sh" ]; then
                    source lib/system-check.sh
                    run_system_check
                else
                    echo -e "${YELLOW}System check module not available${NC}"
                fi
                exit $? ;;
            --security-check)
                if [ -f "lib/security.sh" ]; then
                    source lib/security.sh
                    run_security_check
                else
                    echo -e "${YELLOW}Security check module not available${NC}"
                fi
                exit $? ;;
            -c|--config)
                CONFIG_FILE="$2"
                shift 2 ;;
            --skip-checks)
                SKIP_SYSTEM_CHECK=true
                SKIP_SECURITY_CHECK=true
                shift ;;
            --parallel)
                PARALLEL_INSTALL=true
                shift ;;
            --timeout)
                TIMEOUT="$2"
                shift 2 ;;
            --log-level)
                LOG_LEVEL="$2"
                shift 2 ;;
            --gui)
                ENABLE_GUI=true
                shift ;;
            --docker)
                ENABLE_DOCKER=true
                shift ;;
            --plugins)
                ENABLE_PLUGINS=true
                shift ;;
            --analytics)
                ENABLE_ANALYTICS=true
                shift ;;
            --cloud)
                ENABLE_CLOUD=true
                shift ;;
            --gpu)
                ENABLE_GPU=true
                shift ;;
            --auto-gpu)
                ENABLE_GPU=true
                AUTO_GPU=true
                shift ;;
            basic|remote|dev|all)
                PACKAGE_CATEGORY="$1"
                shift ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                echo "Use --help for usage information"
                exit 1 ;;
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
    
    # Auto-check for updates (non-interactive)
    if [ "$SKIP_SYSTEM_CHECK" = false ]; then
        if command -v auto_check_updates &> /dev/null; then
            auto_check_updates
        fi
    fi
    
    # Calculate total steps
    TOTAL_STEPS=6
    [ "$CREATE_BACKUP" = true ] && TOTAL_STEPS=$((TOTAL_STEPS + 1))
    [ "$SKIP_SYSTEM_CHECK" = false ] && TOTAL_STEPS=$((TOTAL_STEPS + 1))
    [ "$SKIP_SECURITY_CHECK" = false ] && TOTAL_STEPS=$((TOTAL_STEPS + 1))
    
    # Download and source system modules
    if [ "$SKIP_SYSTEM_CHECK" = false ] || [ "$SKIP_SECURITY_CHECK" = false ]; then
        step "Downloading system modules"
        
        # Download system check module
        if [ "$SKIP_SYSTEM_CHECK" = false ]; then
            local temp_system_check=$(mktemp)
            if curl -fsSL "$BASE_URL/lib/system-check.sh" -o "$temp_system_check" 2>/dev/null; then
                source "$temp_system_check"
                rm -f "$temp_system_check"
            else
                echo -e "${YELLOW}⚠️ Could not download system check module${NC}"
                SKIP_SYSTEM_CHECK=true
            fi
        fi
        
        # Download security module
        if [ "$SKIP_SECURITY_CHECK" = false ]; then
            local temp_security=$(mktemp)
            if curl -fsSL "$BASE_URL/lib/security.sh" -o "$temp_security" 2>/dev/null; then
                source "$temp_security"
                rm -f "$temp_security"
            else
                echo -e "${YELLOW}⚠️ Could not download security module${NC}"
                SKIP_SECURITY_CHECK=true
            fi
        fi
        
        # Download update manager
        local temp_update=$(mktemp)
        if curl -fsSL "$BASE_URL/lib/update-manager.sh" -o "$temp_update" 2>/dev/null; then
            source "$temp_update"
            rm -f "$temp_update"
        fi
    fi
    
    # Run system requirements check
    if [ "$SKIP_SYSTEM_CHECK" = false ] && command -v run_system_check &> /dev/null; then
        if ! run_system_check; then
            echo -e "${RED}❌ System requirements not met${NC}"
            echo -e "${YELLOW}Use --skip-checks to bypass (not recommended)${NC}"
            exit 1
        fi
    fi
    
    # Run security check
    if [ "$SKIP_SECURITY_CHECK" = false ] && command -v run_security_check &> /dev/null; then
        if ! run_security_check; then
            echo -e "${RED}❌ Security checks failed${NC}"
            echo -e "${YELLOW}Use --skip-checks to bypass (not recommended)${NC}"
            exit 1
        fi
    fi
    
    check_network
    create_backup
    
    local os=$(detect_os)
    step "Detected OS: $os"
    
    # Initialize additional modules if requested
    if [ "$ENABLE_GUI" = true ]; then
        step "Loading GUI interface"
        if download_and_source "lib/gui-interface.sh"; then
            # Use GUI for package selection if no category specified
            if [ -z "$PACKAGE_CATEGORY" ]; then
                PACKAGE_CATEGORY=$(show_package_selection_gui "$os" || echo "basic")
            fi
        else
            echo -e "${YELLOW}⚠️  GUI interface not available, continuing with CLI${NC}"
        fi
    fi
    
    # Initialize analytics
    if [ "$ENABLE_ANALYTICS" = true ]; then
        step "Initializing analytics"
        if download_and_source "lib/analytics.sh"; then
            init_analytics true
            track_installation_start "$PACKAGE_CATEGORY" "gui:$ENABLE_GUI,docker:$ENABLE_DOCKER,plugins:$ENABLE_PLUGINS,cloud:$ENABLE_CLOUD"
        fi
    fi
    
    # Initialize plugin system
    if [ "$ENABLE_PLUGINS" = true ]; then
        step "Loading plugin system"
        if download_and_source "lib/plugin-system.sh"; then
            init_plugin_system
            load_enabled_plugins
            execute_hook "pre_install" "$PACKAGE_CATEGORY" "$os"
        fi
    fi
    
    # Install Docker support
    if [ "$ENABLE_DOCKER" = true ]; then
        step "Setting up Docker support"
        if download_and_source "lib/docker-support.sh"; then
            setup_docker "$os" true false true
        fi
    fi
    
    # Install cloud tools
    if [ "$ENABLE_CLOUD" = true ]; then
        step "Setting up cloud integration"
        if download_and_source "lib/cloud-integration.sh"; then
            setup_cloud_tools "aws,azure,gcp" "$os" true true true
        fi
    fi
    
    # Install GPU support
    if [ "$ENABLE_GPU" = true ]; then
        step "Setting up GPU environment"
        if download_and_source "lib/gpu-support.sh"; then
            if [ "$AUTO_GPU" = true ]; then
                auto_install_gpu_drivers
            else
                setup_gpu_support
            fi
        fi
    fi
    
    # Pass additional flags to sub-scripts
    local script_args=()
    [ "$FORCE_INSTALL" = true ] && script_args+=("--force")
    [ "$SKIP_SNAP" = true ] && script_args+=("--no-snap")
    [ "$SKIP_FLATPAK" = true ] && script_args+=("--no-flatpak")
    [ "$PARALLEL_INSTALL" = true ] && script_args+=("--parallel")
    [ -n "$PACKAGE_CATEGORY" ] && script_args+=("$PACKAGE_CATEGORY")
    
    case $os in
        "debian")
            download_and_run "linux/install-debian.sh" "${script_args[@]}"
            ;;
        "fedora")
            download_and_run "linux/install-fedora.sh" "${script_args[@]}"
            ;;
        "arch")
            download_and_run "linux/install-arch.sh" "${script_args[@]}"
            ;;
        "macos")
            download_and_run "macos/install-macos.sh" "${script_args[@]}"
            ;;
        "windows")
            echo -e "${CYAN}🪟 Windows detected!${NC}"
            echo -e "${YELLOW}Please run this PowerShell command:${NC}"
            echo "irm $BASE_URL/install.ps1 | iex"
            if [ -n "$PACKAGE_CATEGORY" ]; then
                echo -e "${BLUE}Or with package set:${NC}"
                echo "irm $BASE_URL/install.ps1 | iex -PackageSet $PACKAGE_CATEGORY"
            fi
            ;;
        *)
            echo -e "${RED}❌ Unsupported OS: $os${NC}"
            exit 1
            ;;
    esac
    
    step "Installation complete"
    
    # Execute post-installation hooks
    if [ "$ENABLE_PLUGINS" = true ] && command -v execute_hook &> /dev/null; then
        execute_hook "post_install" "$PACKAGE_CATEGORY" "true"
    fi
    
    # Track completion
    if [ "$ENABLE_ANALYTICS" = true ] && command -v track_installation_complete &> /dev/null; then
        local end_time=$(date +%s)
        local duration=$((end_time - START_TIME))
        track_installation_complete "$PACKAGE_CATEGORY" "true" "" "$duration" "0"
    fi
    
    # Show GUI completion dialog
    if [ "$ENABLE_GUI" = true ] && command -v show_completion_gui &> /dev/null; then
        show_completion_gui "Installation completed successfully!" "Machine Bootstrap has finished installing packages."
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))
    
    if [ "$QUIET" = false ]; then
        echo ""
        echo -e "${GREEN}✅ Bootstrap complete! (${duration}s)${NC}"
        echo -e "${YELLOW}Log file: $LOG_FILE${NC}"
        [ "$CREATE_BACKUP" = true ] && echo -e "${YELLOW}Backup: $BACKUP_DIR${NC}"
        echo -e "${BLUE}⭐ Star the repo: https://github.com/${GITHUB_USER}/${REPO_NAME}${NC}"
        echo ""
        echo -e "${CYAN}💡 Helpful commands:${NC}"
        echo -e "${WHITE}  Check for updates: curl -fsSL $BASE_URL/install.sh | bash -s -- --check-updates${NC}"
        echo -e "${WHITE}  Run maintenance:   curl -fsSL $BASE_URL/lib/update-manager.sh | bash -s maintenance${NC}"
        echo -e "${WHITE}  Security check:    curl -fsSL $BASE_URL/install.sh | bash -s -- --security-check${NC}"
    fi
}

main "$@"
