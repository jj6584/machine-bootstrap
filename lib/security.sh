#!/bin/bash

# Package Verification & Security Module
# Verifies package integrity and security before installation

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Security configuration
VERIFY_CHECKSUMS=true
VERIFY_SIGNATURES=true
ALLOW_UNTRUSTED=false
SECURITY_LOG="/tmp/machine-bootstrap-security.log"

# Known package hashes (for critical packages)
declare -A PACKAGE_HASHES=(
    ["docker.io"]="sha256:abc123..."
    ["git"]="sha256:def456..."
    # Add more as needed
)

# Initialize security logging
init_security_log() {
    echo "# Machine Bootstrap Security Log - $(date)" > "$SECURITY_LOG"
    echo "# This log contains security verification results" >> "$SECURITY_LOG"
    echo "" >> "$SECURITY_LOG"
}

# Log security events
log_security() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] [$level] $message" >> "$SECURITY_LOG"
    
    case $level in
        "ERROR")
            echo -e "${RED}🔒 [SECURITY] $message${NC}" >&2
            ;;
        "WARNING")
            echo -e "${YELLOW}⚠️ [SECURITY] $message${NC}"
            ;;
        "INFO")
            echo -e "${BLUE}🔍 [SECURITY] $message${NC}"
            ;;
    esac
}

# Verify script integrity
verify_script_integrity() {
    local script_url=$1
    local expected_hash=$2
    
    if [ -z "$expected_hash" ]; then
        log_security "WARNING" "No hash provided for script verification: $script_url"
        return 0
    fi
    
    log_security "INFO" "Verifying script integrity: $script_url"
    
    local temp_file=$(mktemp)
    if ! curl -fsSL "$script_url" -o "$temp_file"; then
        log_security "ERROR" "Failed to download script for verification: $script_url"
        rm -f "$temp_file"
        return 1
    fi
    
    local actual_hash=$(sha256sum "$temp_file" | cut -d' ' -f1)
    
    if [ "$actual_hash" != "$expected_hash" ]; then
        log_security "ERROR" "Script integrity check failed!"
        log_security "ERROR" "Expected: $expected_hash"
        log_security "ERROR" "Actual:   $actual_hash"
        rm -f "$temp_file"
        return 1
    fi
    
    log_security "INFO" "Script integrity verified successfully"
    rm -f "$temp_file"
    return 0
}

# Check for malicious processes
check_malicious_processes() {
    log_security "INFO" "Scanning for suspicious processes"
    
    local suspicious_patterns=(
        "keylogger"
        "backdoor"
        "malware"
        "trojan"
        "rootkit"
        "cryptominer"
        "botnet"
    )
    
    for pattern in "${suspicious_patterns[@]}"; do
        if pgrep -if "$pattern" > /dev/null; then
            log_security "ERROR" "Suspicious process detected: $pattern"
            echo -e "${RED}⚠️ Suspicious process detected: $pattern${NC}"
            echo -e "${YELLOW}Recommendation: Investigate before proceeding${NC}"
            
            if [ "$ALLOW_UNTRUSTED" = false ]; then
                return 1
            fi
        fi
    done
    
    log_security "INFO" "No suspicious processes detected"
    return 0
}

# Verify package repository authenticity
verify_repository() {
    local repo_url=$1
    local package_manager=$2
    
    log_security "INFO" "Verifying repository: $repo_url ($package_manager)"
    
    case $package_manager in
        "apt")
            # Check if repository is in trusted sources
            if ! apt-cache policy | grep -q "$repo_url"; then
                log_security "WARNING" "Repository not in trusted sources: $repo_url"
            fi
            ;;
        "dnf"|"yum")
            # Check repository configuration
            if ! dnf repolist | grep -q "$(basename "$repo_url")"; then
                log_security "WARNING" "Repository not configured: $repo_url"
            fi
            ;;
        "brew")
            # Homebrew repositories are generally trusted
            log_security "INFO" "Homebrew repository considered trusted"
            ;;
        "choco")
            # Check if using official Chocolatey repository
            if [[ "$repo_url" != *"chocolatey.org"* ]]; then
                log_security "WARNING" "Non-official Chocolatey repository: $repo_url"
            fi
            ;;
    esac
    
    return 0
}

# Verify package before installation
verify_package() {
    local package_name=$1
    local package_manager=$2
    
    log_security "INFO" "Verifying package: $package_name ($package_manager)"
    
    # Check if package exists in official repositories
    case $package_manager in
        "apt")
            if ! apt-cache show "$package_name" &> /dev/null; then
                log_security "ERROR" "Package not found in repositories: $package_name"
                return 1
            fi
            ;;
        "dnf")
            if ! dnf info "$package_name" &> /dev/null; then
                log_security "ERROR" "Package not found in repositories: $package_name"
                return 1
            fi
            ;;
        "pacman")
            if ! pacman -Si "$package_name" &> /dev/null; then
                log_security "ERROR" "Package not found in repositories: $package_name"
                return 1
            fi
            ;;
        "brew")
            if ! brew info "$package_name" &> /dev/null; then
                log_security "WARNING" "Package info not available: $package_name"
            fi
            ;;
        "choco")
            if ! choco info "$package_name" &> /dev/null; then
                log_security "WARNING" "Package info not available: $package_name"
            fi
            ;;
    esac
    
    # Check against known package hashes if available
    if [ -n "${PACKAGE_HASHES[$package_name]}" ]; then
        log_security "INFO" "Known hash available for $package_name, verification recommended"
    fi
    
    log_security "INFO" "Package verification completed: $package_name"
    return 0
}

# Check system security status
check_system_security() {
    log_security "INFO" "Performing system security check"
    
    local security_issues=()
    
    # Check if firewall is enabled (Linux)
    if command -v ufw &> /dev/null; then
        if ! ufw status | grep -q "Status: active"; then
            security_issues+=("Firewall not active")
        fi
    elif command -v firewall-cmd &> /dev/null; then
        if ! firewall-cmd --state &> /dev/null; then
            security_issues+=("Firewall not running")
        fi
    fi
    
    # Check for automatic updates
    if command -v apt &> /dev/null; then
        if [ ! -f "/etc/apt/apt.conf.d/20auto-upgrades" ]; then
            security_issues+=("Automatic updates not configured")
        fi
    fi
    
    # Check SSH configuration (if SSH is installed)
    if [ -f "/etc/ssh/sshd_config" ]; then
        if grep -q "PermitRootLogin yes" "/etc/ssh/sshd_config"; then
            security_issues+=("SSH root login enabled")
        fi
        if grep -q "PasswordAuthentication yes" "/etc/ssh/sshd_config"; then
            security_issues+=("SSH password authentication enabled")
        fi
    fi
    
    # Report security issues
    if [ ${#security_issues[@]} -gt 0 ]; then
        log_security "WARNING" "Security issues detected:"
        for issue in "${security_issues[@]}"; do
            log_security "WARNING" "  - $issue"
        done
        echo -e "${YELLOW}⚠️ Security recommendations available in log: $SECURITY_LOG${NC}"
    else
        log_security "INFO" "No major security issues detected"
    fi
    
    return 0
}

# Verify download integrity
verify_download() {
    local file_path=$1
    local expected_hash=$2
    local hash_algorithm=${3:-"sha256"}
    
    if [ ! -f "$file_path" ]; then
        log_security "ERROR" "File not found for verification: $file_path"
        return 1
    fi
    
    if [ -z "$expected_hash" ]; then
        log_security "WARNING" "No hash provided for verification: $file_path"
        return 0
    fi
    
    log_security "INFO" "Verifying download integrity: $file_path"
    
    local actual_hash
    case $hash_algorithm in
        "sha256")
            actual_hash=$(sha256sum "$file_path" | cut -d' ' -f1)
            ;;
        "sha1")
            actual_hash=$(sha1sum "$file_path" | cut -d' ' -f1)
            ;;
        "md5")
            actual_hash=$(md5sum "$file_path" | cut -d' ' -f1)
            ;;
        *)
            log_security "ERROR" "Unsupported hash algorithm: $hash_algorithm"
            return 1
            ;;
    esac
    
    if [ "$actual_hash" != "$expected_hash" ]; then
        log_security "ERROR" "Download integrity check failed!"
        log_security "ERROR" "Expected ($hash_algorithm): $expected_hash"
        log_security "ERROR" "Actual ($hash_algorithm):   $actual_hash"
        return 1
    fi
    
    log_security "INFO" "Download integrity verified successfully"
    return 0
}

# Main security check function
run_security_check() {
    echo -e "${CYAN}🔒 Running Security Checks...${NC}"
    
    init_security_log
    
    local checks=(
        "check_malicious_processes"
        "check_system_security"
    )
    
    local failed_checks=()
    
    for check in "${checks[@]}"; do
        if ! $check; then
            failed_checks+=("$check")
        fi
    done
    
    if [ ${#failed_checks[@]} -eq 0 ]; then
        echo -e "${GREEN}✅ Security checks passed${NC}"
        log_security "INFO" "All security checks completed successfully"
        return 0
    else
        echo -e "${RED}❌ ${#failed_checks[@]} security check(s) failed${NC}"
        echo -e "${YELLOW}Check security log: $SECURITY_LOG${NC}"
        
        if [ "$ALLOW_UNTRUSTED" = false ]; then
            echo -e "${RED}Aborting due to security concerns${NC}"
            return 1
        else
            echo -e "${YELLOW}Continuing despite security warnings (ALLOW_UNTRUSTED=true)${NC}"
            return 0
        fi
    fi
}

# Safe package installation wrapper
safe_install() {
    local package_name=$1
    local package_manager=$2
    
    echo -e "${BLUE}🔒 Performing safe installation: $package_name${NC}"
    
    # Verify package before installation
    if ! verify_package "$package_name" "$package_manager"; then
        log_security "ERROR" "Package verification failed: $package_name"
        return 1
    fi
    
    # Log installation attempt
    log_security "INFO" "Installing package: $package_name ($package_manager)"
    
    # Perform actual installation
    case $package_manager in
        "apt")
            sudo apt install -y "$package_name"
            ;;
        "dnf")
            sudo dnf install -y "$package_name"
            ;;
        "pacman")
            sudo pacman -S --noconfirm "$package_name"
            ;;
        "brew")
            brew install "$package_name"
            ;;
        "choco")
            choco install -y "$package_name"
            ;;
        *)
            log_security "ERROR" "Unsupported package manager: $package_manager"
            return 1
            ;;
    esac
    
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        log_security "INFO" "Package installed successfully: $package_name"
    else
        log_security "ERROR" "Package installation failed: $package_name (exit code: $exit_code)"
    fi
    
    return $exit_code
}

# Export functions for use in other scripts
export -f verify_script_integrity
export -f verify_package
export -f verify_download
export -f safe_install
export -f run_security_check

# If script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_security_check
fi
