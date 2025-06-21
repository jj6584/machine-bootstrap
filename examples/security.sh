#!/bin/bash

# Security improvements

# Verify script integrity
verify_script_integrity() {
    local script_url=$1
    local expected_hash=$2
    
    echo "🔒 Verifying script integrity..."
    
    local temp_file=$(mktemp)
    curl -fsSL "$script_url" -o "$temp_file"
    
    local actual_hash=$(sha256sum "$temp_file" | cut -d' ' -f1)
    
    if [ "$actual_hash" != "$expected_hash" ]; then
        echo -e "${RED}❌ Script integrity check failed!${NC}"
        echo "Expected: $expected_hash"
        echo "Actual:   $actual_hash"
        rm "$temp_file"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Script integrity verified${NC}"
    rm "$temp_file"
}

# Check for suspicious processes
security_check() {
    echo "🔍 Running security checks..."
    
    # Check for running suspicious processes
    if pgrep -f "keylogger\|backdoor\|malware" > /dev/null; then
        echo -e "${RED}⚠️ Suspicious processes detected!${NC}"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
    fi
    
    # Check disk space
    local available_space=$(df / | awk 'NR==2 {print $4}')
    local required_space=1048576  # 1GB in KB
    
    if [ "$available_space" -lt "$required_space" ]; then
        echo -e "${RED}❌ Insufficient disk space${NC}"
        echo "Available: $(( available_space / 1024 ))MB"
        echo "Required: $(( required_space / 1024 ))MB"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Security checks passed${NC}"
}

# Safe package installation with verification
safe_install() {
    local package=$1
    
    # Check if package exists in repository
    if ! apt-cache show "$package" &> /dev/null; then
        echo -e "${RED}❌ Package '$package' not found in repositories${NC}"
        return 1
    fi
    
    # Check package signature (if available)
    echo "Installing $package with verification..."
    sudo apt install -y "$package"
}
