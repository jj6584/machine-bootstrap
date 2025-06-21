#!/bin/bash

# Plugin system for Machine Bootstrap
# Allows extending functionality through modular plugins

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Plugin system configuration
PLUGINS_DIR="$HOME/.config/machine-bootstrap/plugins"
PLUGINS_REGISTRY="https://raw.githubusercontent.com/jj6584/machine-bootstrap-plugins/main/registry.json"
PLUGINS_CONFIG="$HOME/.config/machine-bootstrap/plugins.conf"

# Plugin metadata structure
declare -A LOADED_PLUGINS
declare -A PLUGIN_HOOKS

# Initialize plugin system
init_plugin_system() {
    echo -e "${CYAN}🔌 Initializing plugin system${NC}"
    
    # Create plugins directory
    mkdir -p "$PLUGINS_DIR"
    mkdir -p "$PLUGINS_DIR/available"
    mkdir -p "$PLUGINS_DIR/enabled"
    mkdir -p "$PLUGINS_DIR/cache"
    
    # Create default plugin config
    if [ ! -f "$PLUGINS_CONFIG" ]; then
        cat > "$PLUGINS_CONFIG" << 'EOF'
# Machine Bootstrap Plugin Configuration
# Enabled plugins (one per line)
# Format: plugin_name:version (version is optional)

# Example plugins:
# company-packages:1.0
# custom-security:latest
# development-tools:2.1
EOF
    fi
    
    # Load enabled plugins
    load_enabled_plugins
    
    echo -e "${GREEN}✅ Plugin system initialized${NC}"
}

# Load enabled plugins
load_enabled_plugins() {
    if [ ! -f "$PLUGINS_CONFIG" ]; then
        return 0
    fi
    
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^#.*$ ]] || [[ -z "$line" ]] && continue
        
        local plugin_spec="$line"
        local plugin_name=$(echo "$plugin_spec" | cut -d':' -f1)
        local plugin_version=$(echo "$plugin_spec" | cut -d':' -f2 -s)
        
        if [ -z "$plugin_version" ]; then
            plugin_version="latest"
        fi
        
        load_plugin "$plugin_name" "$plugin_version"
    done < "$PLUGINS_CONFIG"
}

# Load a specific plugin
load_plugin() {
    local plugin_name="$1"
    local plugin_version="${2:-latest}"
    
    local plugin_path="$PLUGINS_DIR/enabled/${plugin_name}"
    
    if [ ! -f "$plugin_path/plugin.sh" ]; then
        echo -e "${YELLOW}⚠️  Plugin $plugin_name not found, attempting to install...${NC}"
        if ! install_plugin "$plugin_name" "$plugin_version"; then
            echo -e "${RED}❌ Failed to install plugin: $plugin_name${NC}"
            return 1
        fi
    fi
    
    # Load plugin metadata
    if [ -f "$plugin_path/plugin.json" ]; then
        local metadata=$(cat "$plugin_path/plugin.json")
        echo -e "${BLUE}Loading plugin: $plugin_name v$(echo "$metadata" | jq -r '.version' 2>/dev/null || echo 'unknown')${NC}"
    else
        echo -e "${BLUE}Loading plugin: $plugin_name${NC}"
    fi
    
    # Source the plugin
    if source "$plugin_path/plugin.sh"; then
        LOADED_PLUGINS["$plugin_name"]="$plugin_version"
        
        # Register plugin hooks if function exists
        if declare -f "${plugin_name}_register_hooks" >/dev/null; then
            "${plugin_name}_register_hooks"
        fi
        
        echo -e "${GREEN}✅ Plugin loaded: $plugin_name${NC}"
    else
        echo -e "${RED}❌ Failed to load plugin: $plugin_name${NC}"
        return 1
    fi
}

# Install a plugin from registry
install_plugin() {
    local plugin_name="$1"
    local plugin_version="${2:-latest}"
    
    echo -e "${CYAN}📦 Installing plugin: $plugin_name ($plugin_version)${NC}"
    
    # Get plugin info from registry
    local plugin_info
    if ! plugin_info=$(get_plugin_info "$plugin_name"); then
        echo -e "${RED}❌ Plugin not found in registry: $plugin_name${NC}"
        return 1
    fi
    
    local plugin_url=$(echo "$plugin_info" | jq -r '.download_url' 2>/dev/null)
    local plugin_checksum=$(echo "$plugin_info" | jq -r '.checksum' 2>/dev/null)
    
    if [ -z "$plugin_url" ] || [ "$plugin_url" = "null" ]; then
        echo -e "${RED}❌ Invalid plugin URL for: $plugin_name${NC}"
        return 1
    fi
    
    # Download plugin
    local temp_file=$(mktemp)
    local plugin_dir="$PLUGINS_DIR/available/$plugin_name"
    
    if curl -fsSL "$plugin_url" -o "$temp_file"; then
        # Verify checksum if provided
        if [ -n "$plugin_checksum" ] && [ "$plugin_checksum" != "null" ]; then
            local actual_checksum=$(sha256sum "$temp_file" | cut -d' ' -f1)
            if [ "$actual_checksum" != "$plugin_checksum" ]; then
                echo -e "${RED}❌ Checksum verification failed for plugin: $plugin_name${NC}"
                rm -f "$temp_file"
                return 1
            fi
        fi
        
        # Extract plugin
        mkdir -p "$plugin_dir"
        if [[ "$plugin_url" == *.tar.gz ]] || [[ "$plugin_url" == *.tgz ]]; then
            tar -xzf "$temp_file" -C "$plugin_dir"
        elif [[ "$plugin_url" == *.zip ]]; then
            unzip -q "$temp_file" -d "$plugin_dir"
        else
            # Assume it's a single script file
            mv "$temp_file" "$plugin_dir/plugin.sh"
            chmod +x "$plugin_dir/plugin.sh"
        fi
        
        rm -f "$temp_file"
    else
        echo -e "${RED}❌ Failed to download plugin: $plugin_name${NC}"
        rm -f "$temp_file"
        return 1
    fi
    
    # Validate plugin structure
    if [ ! -f "$plugin_dir/plugin.sh" ]; then
        echo -e "${RED}❌ Invalid plugin structure: missing plugin.sh${NC}"
        rm -rf "$plugin_dir"
        return 1
    fi
    
    # Enable plugin
    rm -rf "$PLUGINS_DIR/enabled/$plugin_name"
    cp -r "$plugin_dir" "$PLUGINS_DIR/enabled/$plugin_name"
    
    echo -e "${GREEN}✅ Plugin installed: $plugin_name${NC}"
    return 0
}

# Get plugin information from registry
get_plugin_info() {
    local plugin_name="$1"
    local cache_file="$PLUGINS_DIR/cache/registry.json"
    local cache_age=3600  # 1 hour
    
    # Update cache if old or missing
    if [ ! -f "$cache_file" ] || [ $(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0))) -gt $cache_age ]; then
        echo -e "${BLUE}Updating plugin registry...${NC}"
        if curl -fsSL "$PLUGINS_REGISTRY" -o "$cache_file"; then
            echo -e "${GREEN}✅ Registry updated${NC}"
        else
            echo -e "${YELLOW}⚠️  Failed to update registry, using cache${NC}"
        fi
    fi
    
    if [ -f "$cache_file" ]; then
        jq -r ".plugins[] | select(.name == \"$plugin_name\")" "$cache_file" 2>/dev/null
    else
        echo "null"
        return 1
    fi
}

# List available plugins
list_available_plugins() {
    echo -e "${CYAN}📋 Available Plugins${NC}"
    
    local cache_file="$PLUGINS_DIR/cache/registry.json"
    
    # Try to update registry but don't fail if it doesn't exist
    get_plugin_info "dummy" > /dev/null 2>&1 || true
    
    if [ -f "$cache_file" ]; then
        echo -e "${BLUE}From registry:${NC}"
        if jq -r '.plugins[]? | "  \(.name) v\(.version) - \(.description)"' "$cache_file" 2>/dev/null | grep -v "^$"; then
            :  # Success, jq worked and found plugins
        else
            echo "  No plugins available in registry"
        fi
    else
        echo -e "${BLUE}From registry:${NC}"
        echo "  No registry available (this is normal for development)"
    fi
    
    echo ""
    echo -e "${BLUE}Locally installed:${NC}"
    local found_local=false
    for plugin_dir in "$PLUGINS_DIR/available"/*; do
        if [ -d "$plugin_dir" ]; then
            local plugin_name=$(basename "$plugin_dir")
            local version="unknown"
            if [ -f "$plugin_dir/plugin.json" ]; then
                version=$(jq -r '.version' "$plugin_dir/plugin.json" 2>/dev/null || echo "unknown")
            fi
            echo "  $plugin_name v$version"
            found_local=true
        fi
    done
    
    if [ "$found_local" = false ]; then
        echo "  No plugins installed locally"
    fi
}

# List enabled plugins
list_enabled_plugins() {
    echo -e "${CYAN}🔌 Enabled Plugins${NC}"
    
    # Check if LOADED_PLUGINS array is set and has elements
    if [ -z "${LOADED_PLUGINS[*]:-}" ]; then
        echo "  No plugins loaded"
        return
    fi
    
    for plugin_name in "${!LOADED_PLUGINS[@]}"; do
        local version="${LOADED_PLUGINS[$plugin_name]}"
        echo "  $plugin_name v$version"
    done
}

# Enable a plugin
enable_plugin() {
    local plugin_name="$1"
    
    # Check if plugin is available
    if [ ! -d "$PLUGINS_DIR/available/$plugin_name" ]; then
        echo -e "${YELLOW}Plugin not found locally, attempting to install...${NC}"
        if ! install_plugin "$plugin_name"; then
            return 1
        fi
    fi
    
    # Copy to enabled directory
    rm -rf "$PLUGINS_DIR/enabled/$plugin_name"
    cp -r "$PLUGINS_DIR/available/$plugin_name" "$PLUGINS_DIR/enabled/$plugin_name"
    
    # Add to config if not already there
    if ! grep -q "^$plugin_name:" "$PLUGINS_CONFIG" 2>/dev/null; then
        echo "$plugin_name:latest" >> "$PLUGINS_CONFIG"
    fi
    
    echo -e "${GREEN}✅ Plugin enabled: $plugin_name${NC}"
}

# Disable a plugin
disable_plugin() {
    local plugin_name="$1"
    
    # Remove from enabled directory
    if [ -d "$PLUGINS_DIR/enabled/$plugin_name" ]; then
        rm -rf "$PLUGINS_DIR/enabled/$plugin_name"
    fi
    
    # Remove from config
    if [ -f "$PLUGINS_CONFIG" ]; then
        sed -i "/^$plugin_name:/d" "$PLUGINS_CONFIG"
    fi
    
    # Unload from memory
    unset LOADED_PLUGINS["$plugin_name"]
    
    echo -e "${GREEN}✅ Plugin disabled: $plugin_name${NC}"
}

# Execute plugin hooks
execute_hook() {
    local hook_name="$1"
    shift
    
    echo -e "${BLUE}Executing hook: $hook_name${NC}"
    
    for plugin_name in "${!LOADED_PLUGINS[@]}"; do
        local hook_function="${plugin_name}_${hook_name}"
        if declare -f "$hook_function" >/dev/null; then
            echo -e "${CYAN}  Running $plugin_name::$hook_name${NC}"
            "$hook_function" "$@" || echo -e "${YELLOW}  Warning: $plugin_name::$hook_name failed${NC}"
        fi
    done
}

# Create example plugin
create_example_plugin() {
    local plugin_name="${1:-example-plugin}"
    local plugin_dir="$PLUGINS_DIR/available/$plugin_name"
    
    echo -e "${CYAN}Creating example plugin: $plugin_name${NC}"
    
    mkdir -p "$plugin_dir"
    
    # Create plugin metadata
    cat > "$plugin_dir/plugin.json" << EOF
{
  "name": "$plugin_name",
  "version": "1.0.0",
  "description": "Example plugin for Machine Bootstrap",
  "author": "User",
  "license": "MIT",
  "compatibility": {
    "min_version": "2.0.0"
  },
  "hooks": [
    "pre_install",
    "post_install",
    "custom_packages"
  ]
}
EOF

    # Create plugin script
    cat > "$plugin_dir/plugin.sh" << 'EOF'
#!/bin/bash

# Example Plugin for Machine Bootstrap
# This demonstrates how to create plugins

# Plugin information (required)
PLUGIN_NAME="example-plugin"
PLUGIN_VERSION="1.0.0"

# Register hooks (called when plugin is loaded)
example_plugin_register_hooks() {
    echo "Registering hooks for $PLUGIN_NAME"
}

# Pre-installation hook
example_plugin_pre_install() {
    local package_category="$1"
    echo "Example plugin: Pre-install hook for $package_category"
    
    # Add custom pre-installation logic here
    # Example: Check for specific requirements
}

# Post-installation hook
example_plugin_post_install() {
    local package_category="$1"
    local success="$2"
    echo "Example plugin: Post-install hook for $package_category (success: $success)"
    
    # Add custom post-installation logic here
    # Example: Configure installed packages
}

# Custom packages hook (modify package lists)
example_plugin_custom_packages() {
    local os_type="$1"
    local package_category="$2"
    
    echo "Example plugin: Adding custom packages for $os_type ($package_category)"
    
    # Return additional packages to install
    case "$os_type" in
        "debian"|"ubuntu")
            echo "htop neofetch"
            ;;
        "macos")
            echo "htop"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Custom command (can be called directly)
example_plugin_hello() {
    echo "Hello from $PLUGIN_NAME v$PLUGIN_VERSION!"
}

# Plugin configuration check
example_plugin_check() {
    echo "Plugin $PLUGIN_NAME is working correctly"
    return 0
}
EOF

    chmod +x "$plugin_dir/plugin.sh"
    
    echo -e "${GREEN}✅ Example plugin created at: $plugin_dir${NC}"
    echo -e "${BLUE}To enable: machine-bootstrap plugin enable $plugin_name${NC}"
}

# Main plugin management function
manage_plugins() {
    local action="$1"
    shift
    
    case "$action" in
        "init")
            init_plugin_system
            ;;
        "list")
            list_available_plugins
            echo ""
            list_enabled_plugins
            ;;
        "available")
            list_available_plugins
            ;;
        "enabled")
            list_enabled_plugins
            ;;
        "install")
            local plugin_name="${1:-}"
            local plugin_version="${2:-latest}"
            if [ -z "$plugin_name" ]; then
                echo -e "${RED}❌ Plugin name required${NC}"
                return 1
            fi
            install_plugin "$plugin_name" "$plugin_version"
            ;;
        "enable")
            local plugin_name="${1:-}"
            if [ -z "$plugin_name" ]; then
                echo -e "${RED}❌ Plugin name required${NC}"
                return 1
            fi
            enable_plugin "$plugin_name"
            ;;
        "disable")
            local plugin_name="${1:-}"
            if [ -z "$plugin_name" ]; then
                echo -e "${RED}❌ Plugin name required${NC}"
                return 1
            fi
            disable_plugin "$plugin_name"
            ;;
        "create")
            local plugin_name="${1:-example-plugin}"
            create_example_plugin "$plugin_name"
            ;;
        *)
            echo "Usage: $0 {init|list|available|enabled|install|enable|disable|create}"
            echo ""
            echo "Actions:"
            echo "  init                    - Initialize plugin system"
            echo "  list                    - List all plugins"
            echo "  available               - List available plugins"
            echo "  enabled                 - List enabled plugins"
            echo "  install <name> [ver]    - Install plugin"
            echo "  enable <name>           - Enable plugin"
            echo "  disable <name>          - Disable plugin"
            echo "  create [name]           - Create example plugin"
            return 1
            ;;
    esac
}

# Export functions for use in main script
export -f init_plugin_system load_enabled_plugins execute_hook

# Handle direct execution
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    manage_plugins "$@"
fi
