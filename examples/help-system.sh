#!/bin/bash

# Help system
show_help() {
    cat << 'EOF'
Machine Bootstrap - Cross-platform development environment setup

USAGE:
    ./install.sh [OPTIONS] [CATEGORY]

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

EXAMPLES:
    ./install.sh basic                    # Install basic packages
    ./install.sh --dry-run dev           # Preview developer package installation
    ./install.sh -c my-config.yml all   # Use custom configuration
    ./install.sh --backup --force dev   # Force install dev tools with backup

CONFIGURATION:
    Default config: ~/.config/machine-bootstrap/config.yml
    Example config: config.yml.example

For more information, visit:
https://github.com/YOUR_USERNAME/machine-bootstrap

EOF
}

show_version() {
    echo "Machine Bootstrap v$SCRIPT_VERSION"
    echo "https://github.com/YOUR_USERNAME/machine-bootstrap"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -b|--backup)
                CREATE_BACKUP=true
                shift
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            -f|--force)
                FORCE_INSTALL=true
                shift
                ;;
            --no-snap)
                SKIP_SNAP=true
                shift
                ;;
            --no-flatpak)
                SKIP_FLATPAK=true
                shift
                ;;
            basic|remote|dev|all)
                PACKAGE_CATEGORY="$1"
                shift
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}
