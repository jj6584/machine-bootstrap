#!/bin/bash

# System Requirements Checker
# Verifies system meets minimum requirements before installation

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default requirements
MIN_DISK_SPACE_GB=2
MIN_RAM_GB=1
REQUIRED_COMMANDS=("curl" "wget")

# Load config if available
load_config() {
    local config_file=""
    
    # Check for config file in order of preference
    if [ -f "./config.yml" ]; then
        config_file="./config.yml"
    elif [ -f "$HOME/.config/machine-bootstrap/config.yml" ]; then
        config_file="$HOME/.config/machine-bootstrap/config.yml"
    fi
    
    if [ -n "$config_file" ] && command -v yq &> /dev/null; then
        MIN_DISK_SPACE_GB=$(yq eval '.requirements.min_disk_space_gb // 2' "$config_file")
        MIN_RAM_GB=$(yq eval '.requirements.min_ram_gb // 1' "$config_file")
        
        # Load required tools
        local tools=$(yq eval '.requirements.required_tools[]? // empty' "$config_file" 2>/dev/null)
        if [ -n "$tools" ]; then
            REQUIRED_COMMANDS=()
            while IFS= read -r tool; do
                REQUIRED_COMMANDS+=("$tool")
            done <<< "$tools"
        fi
    fi
}

# Check disk space
check_disk_space() {
    echo -e "${BLUE}🔍 Checking disk space...${NC}"
    
    local available_gb
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        available_gb=$(df -g / | awk 'NR==2 {print $4}')
    else
        # Linux
        available_gb=$(df -BG / | awk 'NR==2 {gsub(/G/, "", $4); print $4}')
    fi
    
    if [ "$available_gb" -lt "$MIN_DISK_SPACE_GB" ]; then
        echo -e "${RED}❌ Insufficient disk space${NC}"
        echo -e "${YELLOW}Available: ${available_gb}GB${NC}"
        echo -e "${YELLOW}Required: ${MIN_DISK_SPACE_GB}GB${NC}"
        return 1
    else
        echo -e "${GREEN}✅ Disk space OK (${available_gb}GB available)${NC}"
        return 0
    fi
}

# Check RAM
check_ram() {
    echo -e "${BLUE}🔍 Checking RAM...${NC}"
    
    local ram_gb
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        ram_gb=$(sysctl -n hw.memsize | awk '{print int($1/1024/1024/1024)}')
    else
        # Linux
        ram_gb=$(free -g | awk 'NR==2{print $2}')
    fi
    
    if [ "$ram_gb" -lt "$MIN_RAM_GB" ]; then
        echo -e "${RED}❌ Insufficient RAM${NC}"
        echo -e "${YELLOW}Available: ${ram_gb}GB${NC}"
        echo -e "${YELLOW}Required: ${MIN_RAM_GB}GB${NC}"
        return 1
    else
        echo -e "${GREEN}✅ RAM OK (${ram_gb}GB available)${NC}"
        return 0
    fi
}

# Check internet connectivity
check_internet() {
    echo -e "${BLUE}🔍 Checking internet connectivity...${NC}"
    
    local test_urls=("google.com" "github.com" "cloudflare.com")
    local success=false
    
    for url in "${test_urls[@]}"; do
        if ping -c 1 "$url" &> /dev/null; then
            echo -e "${GREEN}✅ Internet connectivity OK${NC}"
            success=true
            break
        fi
    done
    
    if [ "$success" = false ]; then
        echo -e "${RED}❌ No internet connection detected${NC}"
        echo -e "${YELLOW}Please check your network connection${NC}"
        return 1
    fi
    
    return 0
}

# Check required commands
check_required_commands() {
    echo -e "${BLUE}🔍 Checking required commands...${NC}"
    
    local missing_commands=()
    
    for cmd in "${REQUIRED_COMMANDS[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_commands+=("$cmd")
        else
            echo -e "${GREEN}✅ $cmd found${NC}"
        fi
    done
    
    if [ ${#missing_commands[@]} -gt 0 ]; then
        echo -e "${RED}❌ Missing required commands: ${missing_commands[*]}${NC}"
        echo -e "${YELLOW}Please install these commands before continuing${NC}"
        return 1
    fi
    
    return 0
}

# Check OS compatibility
check_os_compatibility() {
    echo -e "${BLUE}🔍 Checking OS compatibility...${NC}"
    
    local os_type=""
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            os_type="Ubuntu/Debian"
        elif command -v dnf &> /dev/null; then
            os_type="Fedora/RHEL"
        elif command -v pacman &> /dev/null; then
            os_type="Arch Linux"
        else
            os_type="Linux (Generic)"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        os_type="macOS"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OS" == "Windows_NT" ]]; then
        os_type="Windows"
    else
        echo -e "${RED}❌ Unsupported operating system: $OSTYPE${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Compatible OS detected: $os_type${NC}"
    return 0
}

# Check permissions
check_permissions() {
    echo -e "${BLUE}🔍 Checking permissions...${NC}"
    
    # Check if we can create temp files
    if ! temp_file=$(mktemp) 2>/dev/null; then
        echo -e "${RED}❌ Cannot create temporary files${NC}"
        return 1
    fi
    rm -f "$temp_file"
    
    # Check sudo access (for Linux/macOS)
    if [[ "$OSTYPE" != "msys" ]] && [[ "$OSTYPE" != "cygwin" ]] && [[ "$OS" != "Windows_NT" ]]; then
        if ! sudo -n true 2>/dev/null; then
            echo -e "${YELLOW}⚠️ Sudo access required. You may be prompted for password${NC}"
        else
            echo -e "${GREEN}✅ Sudo access OK${NC}"
        fi
    fi
    
    echo -e "${GREEN}✅ Permissions OK${NC}"
    return 0
}

# Check package manager availability
check_package_managers() {
    echo -e "${BLUE}🔍 Checking package managers...${NC}"
    
    local found_pm=false
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            echo -e "${GREEN}✅ APT package manager found${NC}"
            found_pm=true
        elif command -v dnf &> /dev/null; then
            echo -e "${GREEN}✅ DNF package manager found${NC}"
            found_pm=true
        elif command -v pacman &> /dev/null; then
            echo -e "${GREEN}✅ Pacman package manager found${NC}"
            found_pm=true
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew &> /dev/null; then
            echo -e "${GREEN}✅ Homebrew found${NC}"
            found_pm=true
        else
            echo -e "${YELLOW}⚠️ Homebrew not found (will be installed)${NC}"
            found_pm=true
        fi
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OS" == "Windows_NT" ]]; then
        if command -v choco &> /dev/null; then
            echo -e "${GREEN}✅ Chocolatey found${NC}"
            found_pm=true
        else
            echo -e "${YELLOW}⚠️ Chocolatey not found (will be installed)${NC}"
            found_pm=true
        fi
    fi
    
    if [ "$found_pm" = false ]; then
        echo -e "${RED}❌ No compatible package manager found${NC}"
        return 1
    fi
    
    return 0
}

# Check GPU and drivers
check_gpu_drivers() {
    echo -e "${BLUE}🔍 Checking GPU and drivers...${NC}"
    
    local gpu_found=false
    local driver_issues=()
    
    # Detect NVIDIA GPUs
    if lspci 2>/dev/null | grep -i nvidia &> /dev/null || [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "${CYAN}🎮 NVIDIA GPU detected${NC}"
        gpu_found=true
        
        # Check NVIDIA driver
        if command -v nvidia-smi &> /dev/null; then
            local nvidia_version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits 2>/dev/null | head -1)
            if [ -n "$nvidia_version" ]; then
                echo -e "${GREEN}✅ NVIDIA driver installed (v$nvidia_version)${NC}"
                
                # Check CUDA if available
                if command -v nvcc &> /dev/null; then
                    local cuda_version=$(nvcc --version | grep "release" | awk '{print $6}' | cut -c2-)
                    echo -e "${GREEN}✅ CUDA toolkit installed (v$cuda_version)${NC}"
                else
                    echo -e "${YELLOW}⚠️ CUDA toolkit not found (optional for development)${NC}"
                fi
            else
                echo -e "${RED}❌ NVIDIA driver installation appears corrupted${NC}"
                driver_issues+=("nvidia_corrupted")
            fi
        else
            echo -e "${YELLOW}⚠️ NVIDIA driver not installed${NC}"
            driver_issues+=("nvidia_missing")
        fi
    fi
    
    # Detect AMD GPUs
    if lspci 2>/dev/null | grep -i amd | grep -i vga &> /dev/null; then
        echo -e "${CYAN}🎮 AMD GPU detected${NC}"
        gpu_found=true
        
        # Check AMD driver (Linux)
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            if [ -d "/sys/module/amdgpu" ] || [ -d "/sys/module/radeon" ]; then
                echo -e "${GREEN}✅ AMD driver (AMDGPU/Radeon) loaded${NC}"
                
                # Check for Mesa/OpenGL
                if command -v glxinfo &> /dev/null; then
                    local mesa_version=$(glxinfo | grep "OpenGL version" | head -1)
                    echo -e "${GREEN}✅ Mesa/OpenGL: $mesa_version${NC}"
                else
                    echo -e "${YELLOW}⚠️ Mesa utilities not installed${NC}"
                    driver_issues+=("mesa_missing")
                fi
            else
                echo -e "${RED}❌ AMD driver not properly loaded${NC}"
                driver_issues+=("amd_missing")
            fi
        fi
    fi
    
    # Detect Intel integrated graphics
    if lspci 2>/dev/null | grep -i intel | grep -i vga &> /dev/null; then
        echo -e "${CYAN}🎮 Intel integrated graphics detected${NC}"
        gpu_found=true
        
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            if [ -d "/sys/module/i915" ]; then
                echo -e "${GREEN}✅ Intel i915 driver loaded${NC}"
            else
                echo -e "${YELLOW}⚠️ Intel graphics driver not loaded${NC}"
                driver_issues+=("intel_missing")
            fi
        fi
    fi
    
    # macOS specific GPU check
    if [[ "$OSTYPE" == "darwin"* ]]; then
        local gpu_info=$(system_profiler SPDisplaysDataType 2>/dev/null | grep "Chipset Model" | head -1 | awk -F: '{print $2}' | xargs)
        if [ -n "$gpu_info" ]; then
            echo -e "${GREEN}✅ macOS GPU: $gpu_info${NC}"
            gpu_found=true
        fi
    fi
    
    # Windows specific GPU check (if running in WSL or similar)
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OS" == "Windows_NT" ]]; then
        echo -e "${YELLOW}⚠️ Windows GPU detection requires PowerShell${NC}"
        gpu_found=true  # Assume GPU present on Windows
    fi
    
    # Check for headless systems
    if [ "$gpu_found" = false ]; then
        echo -e "${CYAN}🖥️ No dedicated GPU detected (headless/server system)${NC}"
        echo -e "${GREEN}✅ GPU not required for server installations${NC}"
    fi
    
    # Report driver issues
    if [ ${#driver_issues[@]} -gt 0 ]; then
        echo -e "${YELLOW}⚠️ GPU driver recommendations:${NC}"
        for issue in "${driver_issues[@]}"; do
            case $issue in
                "nvidia_missing")
                    echo -e "${YELLOW}  • Install NVIDIA drivers: Run with --gpu flag${NC}"
                    ;;
                "nvidia_corrupted")
                    echo -e "${YELLOW}  • Reinstall NVIDIA drivers or reboot system${NC}"
                    ;;
                "amd_missing")
                    echo -e "${YELLOW}  • Install AMD drivers: Run with --gpu flag${NC}"
                    ;;
                "mesa_missing")
                    echo -e "${YELLOW}  • Install Mesa utilities: sudo apt install mesa-utils${NC}"
                    ;;
                "intel_missing")
                    echo -e "${YELLOW}  • Install Intel graphics: Run with --gpu flag${NC}"
                    ;;
            esac
        done
        return 1
    fi
    
    return 0
}

# Check for gaming/graphics specific requirements
check_gaming_requirements() {
    echo -e "${BLUE}🔍 Checking gaming/graphics requirements...${NC}"
    
    local gaming_issues=()
    
    # Check for Vulkan support
    if command -v vulkaninfo &> /dev/null; then
        if vulkaninfo --summary &> /dev/null; then
            echo -e "${GREEN}✅ Vulkan support available${NC}"
        else
            echo -e "${YELLOW}⚠️ Vulkan installed but not working properly${NC}"
            gaming_issues+=("vulkan_broken")
        fi
    else
        echo -e "${YELLOW}⚠️ Vulkan not installed (recommended for gaming)${NC}"
        gaming_issues+=("vulkan_missing")
    fi
    
    # Check for 32-bit library support (Linux)
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v dpkg &> /dev/null && dpkg --print-foreign-architectures | grep -q i386; then
            echo -e "${GREEN}✅ 32-bit library support enabled${NC}"
        else
            echo -e "${YELLOW}⚠️ 32-bit libraries not enabled (needed for some games)${NC}"
            gaming_issues+=("lib32_missing")
        fi
    fi
    
    # Check audio system
    if command -v pulseaudio &> /dev/null || command -v pipewire &> /dev/null; then
        echo -e "${GREEN}✅ Audio system detected${NC}"
    else
        echo -e "${YELLOW}⚠️ No audio system detected${NC}"
        gaming_issues+=("audio_missing")
    fi
    
    if [ ${#gaming_issues[@]} -gt 0 ]; then
        echo -e "${YELLOW}🎮 Gaming setup recommendations:${NC}"
        for issue in "${gaming_issues[@]}"; do
            case $issue in
                "vulkan_missing")
                    echo -e "${YELLOW}  • Install Vulkan: Run with --gpu flag${NC}"
                    ;;
                "vulkan_broken")
                    echo -e "${YELLOW}  • Check GPU drivers and reboot system${NC}"
                    ;;
                "lib32_missing")
                    echo -e "${YELLOW}  • Enable 32-bit support: sudo dpkg --add-architecture i386${NC}"
                    ;;
                "audio_missing")
                    echo -e "${YELLOW}  • Install audio: sudo apt install pulseaudio${NC}"
                    ;;
            esac
        done
    fi
    
    return 0
}

# Main system check function
run_system_check() {
    echo -e "${CYAN}🔧 Running System Requirements Check...${NC}"
    echo ""
    
    load_config
    
    local checks=(
        "check_os_compatibility"
        "check_disk_space"
        "check_ram"
        "check_internet"
        "check_required_commands"
        "check_permissions"
        "check_package_managers"
        "check_gpu_drivers"
        "check_gaming_requirements"
    )
    
    local failed_checks=()
    
    for check in "${checks[@]}"; do
        if ! $check; then
            failed_checks+=("$check")
        fi
        echo ""
    done
    
    echo -e "${CYAN}📊 System Check Summary:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [ ${#failed_checks[@]} -eq 0 ]; then
        echo -e "${GREEN}✅ All system requirements met!${NC}"
        echo -e "${GREEN}🚀 Ready to proceed with installation${NC}"
        return 0
    else
        echo -e "${RED}❌ ${#failed_checks[@]} requirement(s) failed:${NC}"
        for failed in "${failed_checks[@]}"; do
            echo -e "${RED}  • $failed${NC}"
        done
        echo ""
        echo -e "${YELLOW}Please resolve the above issues before continuing${NC}"
        return 1
    fi
}

# If script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_system_check
fi
