#!/bin/bash

# Debian/Ubuntu Package Installer
# Compatible with Ubuntu, Debian, and their derivatives

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Package arrays
declare -a packages_basic=(
    "curl" "wget" "git" "vim" "firefox" "vlc" "snapd"
    "software-properties-common" "apt-transport-https"
)

declare -a packages_remote=(
    "remmina" "remmina-plugin-rdp" "remmina-plugin-vnc"
    "filezilla" "thunderbird"
)

declare -a packages_dev=(
    "nodejs" "npm" "python3" "python3-pip" "docker.io" 
    "docker-compose" "build-essential" "default-jdk"
    "mysql-server" "postgresql" "redis-server"
)

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        echo -e "${RED}❌ This script should not be run as root${NC}"
        exit 1
    fi
}

# Function to install packages
install_packages() {
    local packages=("$@")
    echo -e "${YELLOW}🔄 Updating package lists...${NC}"
    sudo apt update
    
    echo -e "${CYAN}📦 Installing ${#packages[@]} packages...${NC}"
    for package in "${packages[@]}"; do
        echo -e "${BLUE}Installing $package...${NC}"
        sudo apt install -y "$package"
    done
}

# Function to install Snap packages
install_snap_packages() {
    echo -e "${CYAN}📦 Installing Snap packages...${NC}"
    
    # Enable snapd if not running
    sudo systemctl enable --now snapd
    
    # Install snap packages
    sudo snap install discord
    sudo snap install code --classic
    sudo snap install teams-for-linux
    sudo snap install zoom-client
    sudo snap install postman
    sudo snap install steam
}

# Function to install additional repositories
setup_additional_repos() {
    echo -e "${YELLOW}🔧 Setting up additional repositories...${NC}"
    
    # Google Chrome
    if ! command -v google-chrome &> /dev/null; then
        wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
        echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
        sudo apt update
        sudo apt install -y google-chrome-stable
    fi
    
    # Docker (if not installed via apt)
    if ! command -v docker &> /dev/null; then
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io
        sudo usermod -aG docker $USER
    fi
}

# Show menu and handle selection
show_menu() {
    echo -e "${CYAN}📦 Package Installation Options:${NC}"
    echo -e "${WHITE}A - Basic packages (Essential tools, Firefox, etc.)${NC}"
    echo -e "${WHITE}B - Remote work packages (Teams, Zoom, etc.)${NC}" 
    echo -e "${WHITE}C - Developer packages (Docker, Node.js, etc.)${NC}"
    echo -e "${WHITE}D - All packages${NC}"
    echo -e "${RED}E - Exit${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}🐧 Debian/Ubuntu Package Installer${NC}"
    
    check_root
    
    # Handle command line parameters
    if [[ $# -gt 0 ]]; then
        case $1 in
            "basic") install_packages "${packages_basic[@]}"; install_snap_packages; exit ;;
            "remote") install_packages "${packages_remote[@]}"; install_snap_packages; exit ;;
            "dev") install_packages "${packages_dev[@]}"; setup_additional_repos; exit ;;
            "all") 
                install_packages "${packages_basic[@]}"
                install_packages "${packages_remote[@]}"
                install_packages "${packages_dev[@]}"
                install_snap_packages
                setup_additional_repos
                exit ;;
        esac
    fi
    
    # Interactive menu
    local choice
    while true; do
        show_menu
        read -p "Enter your choice: " choice
        
        case $choice in
            [Aa]) 
                install_packages "${packages_basic[@]}"
                install_snap_packages
                break ;;
            [Bb]) 
                install_packages "${packages_remote[@]}"
                install_snap_packages
                break ;;
            [Cc]) 
                install_packages "${packages_dev[@]}"
                setup_additional_repos
                break ;;
            [Dd]) 
                install_packages "${packages_basic[@]}"
                install_packages "${packages_remote[@]}"
                install_packages "${packages_dev[@]}"
                install_snap_packages
                setup_additional_repos
                break ;;
            [Ee]) exit ;;
            *) echo -e "${RED}❌ Invalid input. Please select A, B, C, D, or E.${NC}" ;;
        esac
    done
    
    echo -e "${GREEN}✅ Installation complete!${NC}"
    echo -e "${YELLOW}Note: You may need to log out and back in for some changes to take effect.${NC}"
}

# Run main function
main "$@"
