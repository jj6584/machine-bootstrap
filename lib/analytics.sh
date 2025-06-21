#!/bin/bash

# Analytics and telemetry module (anonymous usage statistics)
# Helps improve the tool by collecting anonymous usage data

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Analytics configuration
ANALYTICS_ENDPOINT="https://api.github.com/repos/jj6584/machine-bootstrap/dispatches"
ANALYTICS_CONFIG_FILE="$HOME/.config/machine-bootstrap/analytics.conf"
SESSION_ID=$(date +%s)-$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 8)
SCRIPT_VERSION="${SCRIPT_VERSION:-2.0.0}"

# Check if analytics is enabled
is_analytics_enabled() {
    if [ -f "$ANALYTICS_CONFIG_FILE" ]; then
        source "$ANALYTICS_CONFIG_FILE"
        [ "${ANALYTICS_ENABLED:-false}" = "true" ]
    else
        false
    fi
}

# Prompt user for analytics consent
prompt_analytics_consent() {
    echo -e "${CYAN}📊 Anonymous Usage Analytics${NC}"
    echo "Help improve Machine Bootstrap by sharing anonymous usage statistics."
    echo ""
    echo "We collect:"
    echo "  ✓ OS type and version"
    echo "  ✓ Package categories installed"
    echo "  ✓ Installation success/failure rates"
    echo "  ✓ Feature usage (GUI, Docker, etc.)"
    echo ""
    echo "We DO NOT collect:"
    echo "  ✗ Personal information"
    echo "  ✗ System passwords or secrets"
    echo "  ✗ File contents or paths"
    echo "  ✗ Network configuration"
    echo ""
    echo "Data is used only for improving the tool and is automatically anonymized."
    echo ""
    
    read -p "Enable anonymous analytics? (y/N): " -n 1 -r
    echo
    
    # Create config directory if it doesn't exist
    mkdir -p "$(dirname "$ANALYTICS_CONFIG_FILE")"
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "ANALYTICS_ENABLED=true" > "$ANALYTICS_CONFIG_FILE"
        echo "ANALYTICS_USER_ID=$(uuidgen 2>/dev/null || echo "$SESSION_ID")" >> "$ANALYTICS_CONFIG_FILE"
        echo "ANALYTICS_CONSENT_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$ANALYTICS_CONFIG_FILE"
        echo -e "${GREEN}✅ Analytics enabled. Thank you for helping improve Machine Bootstrap!${NC}"
        return 0
    else
        echo "ANALYTICS_ENABLED=false" > "$ANALYTICS_CONFIG_FILE"
        echo -e "${BLUE}Analytics disabled. You can enable it later by running with --analytics${NC}"
        return 1
    fi
}

# Get system information (anonymized)
get_system_info() {
    local os_type=""
    local os_version=""
    local arch=""
    
    # Detect OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v lsb_release &> /dev/null; then
            os_type="$(lsb_release -si)"
            os_version="$(lsb_release -sr)"
        elif [ -f /etc/os-release ]; then
            os_type="$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')"
            os_version="$(grep '^VERSION_ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')"
        else
            os_type="linux"
            os_version="unknown"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        os_type="macos"
        os_version="$(sw_vers -productVersion)"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OS" == "Windows_NT" ]]; then
        os_type="windows"
        os_version="$(cmd /c ver 2>/dev/null | grep -o '[0-9]*\.[0-9]*\.[0-9]*' | head -1 || echo 'unknown')"
    fi
    
    # Get architecture
    arch="$(uname -m 2>/dev/null || echo 'unknown')"
    
    # Hash the information to anonymize
    local system_hash=$(echo "${os_type}-${os_version}-${arch}" | sha256sum 2>/dev/null | cut -d' ' -f1 || echo "unknown")
    
    echo "{\"os_type\":\"$os_type\",\"os_version\":\"$os_version\",\"arch\":\"$arch\",\"system_hash\":\"$system_hash\"}"
}

# Track installation start
track_installation_start() {
    local package_category="${1:-unknown}"
    local features="${2:-}"
    
    if ! is_analytics_enabled; then
        return 0
    fi
    
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local system_info=$(get_system_info)
    
    # Load user ID
    source "$ANALYTICS_CONFIG_FILE"
    
    local payload=$(cat << EOF
{
  "event_type": "installation_start",
  "client_payload": {
    "session_id": "$SESSION_ID",
    "user_id": "${ANALYTICS_USER_ID}",
    "timestamp": "$timestamp",
    "script_version": "$SCRIPT_VERSION",
    "package_category": "$package_category",
    "features": "$features",
    "system_info": $system_info
  }
}
EOF
)
    
    # Send data asynchronously (don't block installation)
    (send_analytics_data "$payload" &) 2>/dev/null || true
}

# Track installation completion
track_installation_complete() {
    local package_category="${1:-unknown}"
    local success="${2:-false}"
    local error_message="${3:-}"
    local duration="${4:-0}"
    local packages_installed="${5:-0}"
    
    if ! is_analytics_enabled; then
        return 0
    fi
    
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local system_info=$(get_system_info)
    
    # Load user ID
    source "$ANALYTICS_CONFIG_FILE"
    
    local payload=$(cat << EOF
{
  "event_type": "installation_complete",
  "client_payload": {
    "session_id": "$SESSION_ID",
    "user_id": "${ANALYTICS_USER_ID}",
    "timestamp": "$timestamp",
    "script_version": "$SCRIPT_VERSION",
    "package_category": "$package_category",
    "success": $success,
    "error_message": "$(echo "$error_message" | sed 's/"/\\"/g' | head -c 100)",
    "duration_seconds": $duration,
    "packages_installed": $packages_installed,
    "system_info": $system_info
  }
}
EOF
)
    
    # Send data asynchronously
    (send_analytics_data "$payload" &) 2>/dev/null || true
}

# Track feature usage
track_feature_usage() {
    local feature_name="$1"
    local feature_data="${2:-{}}"
    
    if ! is_analytics_enabled; then
        return 0
    fi
    
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    # Load user ID
    source "$ANALYTICS_CONFIG_FILE"
    
    local payload=$(cat << EOF
{
  "event_type": "feature_usage",
  "client_payload": {
    "session_id": "$SESSION_ID",
    "user_id": "${ANALYTICS_USER_ID}",
    "timestamp": "$timestamp",
    "script_version": "$SCRIPT_VERSION",
    "feature_name": "$feature_name",
    "feature_data": $feature_data
  }
}
EOF
)
    
    # Send data asynchronously
    (send_analytics_data "$payload" &) 2>/dev/null || true
}

# Track error events
track_error() {
    local error_type="$1"
    local error_message="$2"
    local context="${3:-}"
    
    if ! is_analytics_enabled; then
        return 0
    fi
    
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local system_info=$(get_system_info)
    
    # Load user ID
    source "$ANALYTICS_CONFIG_FILE"
    
    local payload=$(cat << EOF
{
  "event_type": "error",
  "client_payload": {
    "session_id": "$SESSION_ID",
    "user_id": "${ANALYTICS_USER_ID}",
    "timestamp": "$timestamp",
    "script_version": "$SCRIPT_VERSION",
    "error_type": "$error_type",
    "error_message": "$(echo "$error_message" | sed 's/"/\\"/g' | head -c 200)",
    "context": "$(echo "$context" | sed 's/"/\\"/g' | head -c 100)",
    "system_info": $system_info
  }
}
EOF
)
    
    # Send data asynchronously
    (send_analytics_data "$payload" &) 2>/dev/null || true
}

# Send analytics data to endpoint
send_analytics_data() {
    local payload="$1"
    local max_retries=3
    local retry=0
    
    # Skip if no network connection
    if ! ping -c 1 8.8.8.8 &>/dev/null; then
        return 0
    fi
    
    while [ $retry -lt $max_retries ]; do
        # Send to GitHub API (using repository dispatch as a simple endpoint)
        if curl -s -X POST \
            -H "Accept: application/vnd.github.v3+json" \
            -H "User-Agent: machine-bootstrap/$SCRIPT_VERSION" \
            -d "$payload" \
            "$ANALYTICS_ENDPOINT" > /dev/null 2>&1; then
            break
        fi
        
        retry=$((retry + 1))
        sleep $((retry * 2))  # Exponential backoff
    done
}

# Show analytics summary
show_analytics_summary() {
    if [ -f "$ANALYTICS_CONFIG_FILE" ]; then
        source "$ANALYTICS_CONFIG_FILE"
        echo -e "${CYAN}📊 Analytics Status${NC}"
        echo "  Enabled: ${ANALYTICS_ENABLED:-false}"
        if [ "${ANALYTICS_ENABLED:-false}" = "true" ]; then
            echo "  User ID: ${ANALYTICS_USER_ID:-unknown}"
            echo "  Consent Date: ${ANALYTICS_CONSENT_DATE:-unknown}"
        fi
    else
        echo -e "${YELLOW}📊 Analytics not configured${NC}"
        echo "  Run with --analytics to configure"
    fi
}

# Disable analytics
disable_analytics() {
    if [ -f "$ANALYTICS_CONFIG_FILE" ]; then
        sed -i 's/ANALYTICS_ENABLED=true/ANALYTICS_ENABLED=false/' "$ANALYTICS_CONFIG_FILE"
        echo -e "${GREEN}✅ Analytics disabled${NC}"
    else
        echo -e "${YELLOW}Analytics not configured${NC}"
    fi
}

# Enable analytics
enable_analytics() {
    prompt_analytics_consent
}

# Get usage statistics (for display to user)
get_usage_stats() {
    echo -e "${CYAN}📈 Usage Statistics${NC}"
    echo "Session ID: $SESSION_ID"
    echo "Script Version: $SCRIPT_VERSION"
    echo "System: $(get_system_info | jq -r '.os_type + " " + .os_version + " " + .arch' 2>/dev/null || echo 'unknown')"
    echo ""
    
    if is_analytics_enabled; then
        echo -e "${GREEN}Analytics: Enabled${NC}"
        echo "Help us improve Machine Bootstrap by contributing anonymous usage data."
    else
        echo -e "${YELLOW}Analytics: Disabled${NC}"
        echo "Enable with --analytics to help improve Machine Bootstrap."
    fi
}

# Main analytics initialization
init_analytics() {
    local enable_analytics_flag="${1:-false}"
    
    # Create config directory
    mkdir -p "$(dirname "$ANALYTICS_CONFIG_FILE")"
    
    # If analytics flag is provided or not configured, prompt for consent
    if [ "$enable_analytics_flag" = "true" ] || [ ! -f "$ANALYTICS_CONFIG_FILE" ]; then
        prompt_analytics_consent
    fi
}

# Export functions for use in main script
export -f is_analytics_enabled track_installation_start track_installation_complete
export -f track_feature_usage track_error show_analytics_summary

# Handle direct execution
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    case "${1:-help}" in
        "init")
            init_analytics "${2:-false}"
            ;;
        "enable")
            enable_analytics
            ;;
        "disable")
            disable_analytics
            ;;
        "status")
            show_analytics_summary
            ;;
        "stats")
            get_usage_stats
            ;;
        *)
            echo "Usage: $0 {init|enable|disable|status|stats}"
            echo ""
            echo "Commands:"
            echo "  init [true|false]  - Initialize analytics (optionally enable)"
            echo "  enable            - Enable analytics"
            echo "  disable           - Disable analytics"
            echo "  status            - Show analytics status"
            echo "  stats             - Show usage statistics"
            ;;
    esac
fi
