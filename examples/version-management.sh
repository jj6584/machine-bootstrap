#!/bin/bash

# Version management system
SCRIPT_VERSION="1.0.0"
VERSION_CHECK_URL="https://api.github.com/repos/YOUR_USERNAME/machine-bootstrap/releases/latest"

check_for_updates() {
    echo "🔍 Checking for updates..."
    
    if command -v jq &> /dev/null; then
        latest_version=$(curl -s "$VERSION_CHECK_URL" | jq -r '.tag_name' | sed 's/^v//')
        
        if [ "$latest_version" != "$SCRIPT_VERSION" ]; then
            echo -e "${YELLOW}📱 New version available: $latest_version (current: $SCRIPT_VERSION)${NC}"
            read -p "Would you like to update? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                update_script
            fi
        else
            echo -e "${GREEN}✅ You're running the latest version${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ Install 'jq' to enable update checking${NC}"
    fi
}

update_script() {
    echo "📥 Downloading latest version..."
    curl -fsSL "https://raw.githubusercontent.com/YOUR_USERNAME/machine-bootstrap/main/install.sh" -o /tmp/install-new.sh
    chmod +x /tmp/install-new.sh
    echo "🔄 Restarting with new version..."
    exec /tmp/install-new.sh "$@"
}
