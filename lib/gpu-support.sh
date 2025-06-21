#!/bin/bash

# GPU Support Module
# Handles GPU driver installation and configuration

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Logging function
log_gpu() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")  echo -e "${CYAN}[${timestamp}] ${BLUE}INFO:${NC} $message" ;;
        "WARN")  echo -e "${CYAN}[${timestamp}] ${YELLOW}WARN:${NC} $message" ;;
        "ERROR") echo -e "${CYAN}[${timestamp}] ${RED}ERROR:${NC} $message" ;;
        "SUCCESS") echo -e "${CYAN}[${timestamp}] ${GREEN}SUCCESS:${NC} $message" ;;
    esac
}

# Install NVIDIA drivers
install_nvidia_drivers() {
    echo -e "${BLUE}🎮 Installing NVIDIA drivers...${NC}"
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            # Ubuntu/Debian
            echo -e "${YELLOW}Adding NVIDIA repository...${NC}"
            sudo apt update
            sudo apt install -y software-properties-common
            sudo add-apt-repository -y ppa:graphics-drivers/ppa
            sudo apt update
            
            # Install latest stable driver
            echo -e "${YELLOW}Installing NVIDIA driver...${NC}"
            sudo apt install -y nvidia-driver-535 nvidia-settings
            
            # Install CUDA if requested
            read -p "Install CUDA toolkit for development? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo -e "${YELLOW}Installing CUDA toolkit...${NC}"
                wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb
                sudo dpkg -i cuda-keyring_1.0-1_all.deb
                sudo apt update
                sudo apt install -y cuda-toolkit
                
                # Add CUDA to PATH
                echo 'export PATH=/usr/local/cuda/bin:$PATH' >> ~/.bashrc
                echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
                
                rm -f cuda-keyring_1.0-1_all.deb
            fi
            
        elif command -v dnf &> /dev/null; then
            # Fedora/RHEL
            echo -e "${YELLOW}Installing NVIDIA drivers on Fedora...${NC}"
            
            # Enable RPM Fusion repositories
            sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
            sudo dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
            
            # Update package cache
            sudo dnf update -y
            
            # Install NVIDIA drivers
            sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda
            sudo dnf install -y nvidia-settings nvidia-persistenced
            
            # Install additional NVIDIA utilities
            sudo dnf install -y vulkan-tools mesa-vulkan-drivers
            
            # Enable nvidia-persistenced service
            sudo systemctl enable nvidia-persistenced
            
        elif command -v pacman &> /dev/null; then
            # Arch Linux
            echo -e "${YELLOW}Installing NVIDIA drivers on Arch...${NC}"
            sudo pacman -S --noconfirm nvidia nvidia-utils nvidia-settings
        fi
        
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "${YELLOW}macOS: NVIDIA drivers handled by system${NC}"
        
    elif [[ "$OS" == "Windows_NT" ]]; then
        echo -e "${YELLOW}Windows: Please download drivers from nvidia.com${NC}"
        echo -e "${CYAN}Opening NVIDIA driver download page...${NC}"
        if command -v start &> /dev/null; then
            start "https://www.nvidia.com/Download/index.aspx"
        else
            echo "https://www.nvidia.com/Download/index.aspx"
        fi
    fi
    
    echo -e "${GREEN}✅ NVIDIA driver installation complete${NC}"
    echo -e "${YELLOW}⚠️ Please reboot your system to activate drivers${NC}"
}

# Install AMD drivers
install_amd_drivers() {
    echo -e "${BLUE}🎮 Installing AMD drivers...${NC}"
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            # Ubuntu/Debian
            echo -e "${YELLOW}Installing AMD drivers...${NC}"
            sudo apt update
            sudo apt install -y mesa-vulkan-drivers mesa-vulkan-drivers:i386
            sudo apt install -y libvulkan1 libvulkan1:i386
            sudo apt install -y vulkan-tools
            
            # Install ROCm for development (optional)
            read -p "Install ROCm for AMD GPU computing? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo -e "${YELLOW}Installing ROCm...${NC}"
                wget -q -O - https://repo.radeon.com/rocm/rocm.gpg.key | sudo apt-key add -
                echo 'deb [arch=amd64] https://repo.radeon.com/rocm/apt/debian/ ubuntu main' | sudo tee /etc/apt/sources.list.d/rocm.list
                sudo apt update
                sudo apt install -y rocm-dev rocm-libs
            fi
            
        elif command -v dnf &> /dev/null; then
            # Fedora/RHEL
            echo -e "${YELLOW}Installing AMD drivers on Fedora...${NC}"
            sudo dnf install -y mesa-vulkan-drivers mesa-vulkan-drivers.i686
            sudo dnf install -y vulkan-tools mesa-libGL mesa-libGL-devel
            
            # Install ROCm for development (optional)
            read -p "Install ROCm for AMD GPU computing? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo -e "${YELLOW}Installing ROCm on Fedora...${NC}"
                # Add ROCm repository
                sudo tee /etc/yum.repos.d/rocm.repo <<EOF
[ROCm]
name=ROCm
baseurl=https://repo.radeon.com/rocm/centos8/rpm
enabled=1
priority=50
gpgcheck=1
gpgkey=https://repo.radeon.com/rocm/rocm.gpg.key
EOF
                sudo dnf update -y
                sudo dnf install -y rocm-dev rocm-libs hip-dev
                
                # Add user to render group
                sudo usermod -a -G render $USER
                echo -e "${YELLOW}⚠️ You need to log out and back in for ROCm group changes to take effect${NC}"
            fi
            
        elif command -v pacman &> /dev/null; then
            # Arch Linux
            echo -e "${YELLOW}Installing AMD drivers on Arch...${NC}"
            sudo pacman -S --noconfirm mesa vulkan-radeon lib32-vulkan-radeon
            sudo pacman -S --noconfirm vulkan-tools
        fi
        
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "${YELLOW}macOS: AMD drivers handled by system${NC}"
        
    elif [[ "$OS" == "Windows_NT" ]]; then
        echo -e "${YELLOW}Windows: Please download drivers from amd.com${NC}"
        echo -e "${CYAN}Opening AMD driver download page...${NC}"
        if command -v start &> /dev/null; then
            start "https://www.amd.com/en/support"
        else
            echo "https://www.amd.com/en/support"
        fi
    fi
    
    echo -e "${GREEN}✅ AMD driver installation complete${NC}"
}

# Install Intel graphics drivers
install_intel_drivers() {
    echo -e "${BLUE}🎮 Installing Intel graphics drivers...${NC}"
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            # Ubuntu/Debian
            echo -e "${YELLOW}Installing Intel graphics drivers...${NC}"
            sudo apt update
            sudo apt install -y mesa-vulkan-drivers mesa-vulkan-drivers:i386
            sudo apt install -y intel-media-va-driver vainfo
            sudo apt install -y xserver-xorg-video-intel
            
        elif command -v dnf &> /dev/null; then
            # Fedora/RHEL
            echo -e "${YELLOW}Installing Intel drivers on Fedora...${NC}"
            sudo dnf install -y mesa-vulkan-drivers mesa-vulkan-drivers.i686
            sudo dnf install -y intel-media-driver
            
        elif command -v pacman &> /dev/null; then
            # Arch Linux
            echo -e "${YELLOW}Installing Intel drivers on Arch...${NC}"
            sudo pacman -S --noconfirm mesa vulkan-intel lib32-vulkan-intel
            sudo pacman -S --noconfirm intel-media-driver
        fi
    fi
    
    echo -e "${GREEN}✅ Intel graphics driver installation complete${NC}"
}

# Setup gaming environment
setup_gaming_environment() {
    echo -e "${BLUE}🎮 Setting up gaming environment...${NC}"
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            # Enable 32-bit architecture
            echo -e "${YELLOW}Enabling 32-bit support...${NC}"
            sudo dpkg --add-architecture i386
            sudo apt update
            
            # Install gaming essentials
            echo -e "${YELLOW}Installing gaming packages...${NC}"
            sudo apt install -y steam-installer lutris wine winetricks
            sudo apt install -y gamemode lib32-gamemode
            sudo apt install -y vulkan-tools mesa-utils
            
            # Install additional libraries
            sudo apt install -y libc6:i386 libgcc-s1:i386 libstdc++6:i386
            sudo apt install -y lib32z1 lib32ncurses6
            
        elif command -v dnf &> /dev/null; then
            # Fedora gaming setup
            echo -e "${YELLOW}Installing gaming packages on Fedora...${NC}"
            sudo dnf install -y steam lutris wine winetricks
            sudo dnf install -y gamemode
            
        elif command -v pacman &> /dev/null; then
            # Arch gaming setup
            echo -e "${YELLOW}Installing gaming packages on Arch...${NC}"
            sudo pacman -S --noconfirm steam lutris wine winetricks
            sudo pacman -S --noconfirm gamemode lib32-gamemode
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "${YELLOW}Installing gaming tools on macOS...${NC}"
        if command -v brew &> /dev/null; then
            brew install --cask steam
            brew install wine-stable
        fi
    fi
    
    echo -e "${GREEN}✅ Gaming environment setup complete${NC}"
}

# Auto-detect and install appropriate GPU drivers
auto_install_gpu_drivers() {
    echo -e "${CYAN}🔍 Auto-detecting GPU and installing drivers...${NC}"
    
    local gpu_detected=false
    
    # Detect NVIDIA
    if lspci 2>/dev/null | grep -i nvidia &> /dev/null; then
        echo -e "${CYAN}NVIDIA GPU detected${NC}"
        install_nvidia_drivers
        gpu_detected=true
    fi
    
    # Detect AMD
    if lspci 2>/dev/null | grep -i amd | grep -i vga &> /dev/null; then
        echo -e "${CYAN}AMD GPU detected${NC}"
        install_amd_drivers
        gpu_detected=true
    fi
    
    # Detect Intel
    if lspci 2>/dev/null | grep -i intel | grep -i vga &> /dev/null; then
        echo -e "${CYAN}Intel GPU detected${NC}"
        install_intel_drivers
        gpu_detected=true
    fi
    
    # macOS GPU detection
    if [[ "$OSTYPE" == "darwin"* ]]; then
        local gpu_info=$(system_profiler SPDisplaysDataType 2>/dev/null | grep "Chipset Model" | head -1 | awk -F: '{print $2}' | xargs)
        if [ -n "$gpu_info" ]; then
            echo -e "${GREEN}✅ macOS GPU detected: $gpu_info${NC}"
            gpu_detected=true
        fi
    fi
    
    if [ "$gpu_detected" = false ]; then
        echo -e "${YELLOW}⚠️ No dedicated GPU detected (headless/server system)${NC}"
        echo -e "${CYAN}This is normal for server installations${NC}"
    fi
    
    echo -e "${GREEN}🎉 GPU driver installation complete${NC}"
}

# GPU diagnostic and information function
gpu_diagnostics() {
    echo -e "${CYAN}🔍 Running GPU Diagnostics...${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # System information
    log_gpu "INFO" "System: $(uname -a)"
    log_gpu "INFO" "Kernel: $(uname -r)"
    
    # GPU detection via lspci
    if command -v lspci &> /dev/null; then
        echo -e "\n${YELLOW}GPU Hardware Detected:${NC}"
        lspci | grep -i vga | while read line; do
            echo -e "${GREEN}  • $line${NC}"
        done
        
        lspci | grep -i 3d | while read line; do
            echo -e "${GREEN}  • $line${NC}"
        done
    fi
    
    # Check for NVIDIA
    if command -v nvidia-smi &> /dev/null; then
        echo -e "\n${GREEN}NVIDIA GPU Status:${NC}"
        nvidia-smi --query-gpu=name,driver_version,memory.total,temperature.gpu --format=csv,noheader,nounits
    fi
    
    # Check for AMD
    if command -v rocm-smi &> /dev/null; then
        echo -e "\n${GREEN}AMD GPU Status (ROCm):${NC}"
        rocm-smi --showproductname --showmeminfo --showtemp
    fi
    
    # Check Vulkan support
    if command -v vulkaninfo &> /dev/null; then
        echo -e "\n${GREEN}Vulkan Support:${NC}"
        vulkaninfo --summary 2>/dev/null | head -20 || echo "Vulkan information unavailable"
    fi
    
    # Check OpenGL support
    if command -v glxinfo &> /dev/null; then
        echo -e "\n${GREEN}OpenGL Support:${NC}"
        glxinfo | grep "OpenGL version" | head -1
        glxinfo | grep "OpenGL renderer" | head -1
    fi
    
    # Display memory information
    echo -e "\n${GREEN}System Memory:${NC}"
    free -h | grep -E "(Mem|Swap)"
    
    # Check for gaming-related packages
    echo -e "\n${GREEN}Gaming Environment:${NC}"
    if command -v steam &> /dev/null; then
        echo -e "${GREEN}  • Steam: Installed${NC}"
    else
        echo -e "${YELLOW}  • Steam: Not installed${NC}"
    fi
    
    if command -v lutris &> /dev/null; then
        echo -e "${GREEN}  • Lutris: Installed${NC}"
    else
        echo -e "${YELLOW}  • Lutris: Not installed${NC}"
    fi
    
    if command -v wine &> /dev/null; then
        echo -e "${GREEN}  • Wine: $(wine --version)${NC}"
    else
        echo -e "${YELLOW}  • Wine: Not installed${NC}"
    fi
}

# Configure GPU for specific workloads
configure_gpu_workload() {
    local workload="$1"
    
    echo -e "${CYAN}🔧 Configuring GPU for $workload workload...${NC}"
    
    case "$workload" in
        "gaming")
            log_gpu "INFO" "Optimizing for gaming performance"
            # Enable gamemode if available
            if command -v gamemoded &> /dev/null; then
                sudo systemctl enable --now gamemoded
                log_gpu "SUCCESS" "GameMode enabled"
            fi
            
            # Configure GPU power management
            if [ -f /sys/class/drm/card0/device/power_dpm_force_performance_level ]; then
                echo "high" | sudo tee /sys/class/drm/card0/device/power_dpm_force_performance_level > /dev/null
                log_gpu "SUCCESS" "GPU performance mode set to high"
            fi
            ;;
            
        "development")
            log_gpu "INFO" "Optimizing for development workloads"
            # Install development tools
            if [[ "$OSTYPE" == "linux-gnu"* ]]; then
                if command -v apt-get &> /dev/null; then
                    sudo apt install -y build-essential cmake git
                elif command -v dnf &> /dev/null; then
                    sudo dnf groupinstall -y "Development Tools"
                    sudo dnf install -y cmake git
                fi
            fi
            ;;
            
        "mining")
            log_gpu "INFO" "Configuring for cryptocurrency mining"
            log_gpu "WARN" "Mining configuration should be done carefully"
            # Set conservative power limits
            ;;
            
        *)
            log_gpu "ERROR" "Unknown workload: $workload"
            return 1
            ;;
    esac
}

# Main GPU setup function
setup_gpu_support() {
    echo -e "${CYAN}🎮 GPU Support Setup${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    echo "GPU Setup Options:"
    echo "1) Auto-detect and install drivers"
    echo "2) Install NVIDIA drivers"
    echo "3) Install AMD drivers" 
    echo "4) Install Intel drivers"
    echo "5) Setup gaming environment"
    echo "6) Run GPU diagnostics"
    echo "7) Configure for gaming workload"
    echo "8) Configure for development workload"
    echo "9) Skip GPU setup"
    
    local gpu_choice
    read -p "Select option (1-9): " gpu_choice
    
    case $gpu_choice in
        1) auto_install_gpu_drivers ;;
        2) install_nvidia_drivers ;;
        3) install_amd_drivers ;;
        4) install_intel_drivers ;;
        5) setup_gaming_environment ;;
        6) gpu_diagnostics ;;
        7) configure_gpu_workload "gaming" ;;
        8) configure_gpu_workload "development" ;;
        9) echo -e "${YELLOW}Skipping GPU setup${NC}" ;;
        *) echo -e "${RED}Invalid option${NC}"; return 1 ;;
    esac
}

# Export functions for use in other scripts
export -f auto_install_gpu_drivers setup_gpu_support install_nvidia_drivers install_amd_drivers install_intel_drivers setup_gaming_environment gpu_diagnostics configure_gpu_workload log_gpu

# If script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_gpu_support
fi
