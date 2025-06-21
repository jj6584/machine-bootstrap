#!/bin/bash

# Fedora/RHEL Package Installer
# Compatible with Fedora, RHEL, CentOS Stream, and derivatives

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
    "dnf-plugins-core"
)

declare -a packages_remote=(
    "remmina" "filezilla" "thunderbird"
)

declare -a packages_dev=(
    "nodejs" "npm" "python3" "python3-pip" "docker" 
    "docker-compose" "@development-tools" "java-11-openjdk-devel"
    "mysql-server" "postgresql" "redis"
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
    sudo dnf update -y
    
    echo -e "${CYAN}📦 Installing ${#packages[@]} packages...${NC}"
    for package in "${packages[@]}"; do
        echo -e "${BLUE}Installing $package...${NC}"
        sudo dnf install -y "$package"
    done
}

# Function to install Flatpak packages
install_flatpak_packages() {
    echo -e "${CYAN}📦 Installing Flatpak packages...${NC}"
    
    # Enable Flatpak if not already
    sudo dnf install -y flatpak
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    
    # Install flatpak packages
    sudo flatpak install -y flathub com.discordapp.Discord
    sudo flatpak install -y flathub com.visualstudio.code
    sudo flatpak install -y flathub com.microsoft.Teams
    sudo flatpak install -y flathub us.zoom.Zoom
    sudo flatpak install -y flathub com.getpostman.Postman
    sudo flatpak install -y flathub com.valvesoftware.Steam
}

# Function to setup additional repositories
setup_additional_repos() {
    echo -e "${YELLOW}🔧 Setting up additional repositories...${NC}"
    
    # Google Chrome
    if ! command -v google-chrome &> /dev/null; then
        sudo dnf config-manager --add-repo https://dl.google.com/linux/chrome/rpm/stable/x86_64/google-chrome.repo
        sudo dnf install -y google-chrome-stable
    fi
    
    # Docker setup
    if ! command -v docker &> /dev/null; then
        sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
        sudo dnf install -y docker-ce docker-ce-cli containerd.io
        sudo systemctl enable --now docker
        sudo usermod -aG docker $USER
    fi
    
    # RPM Fusion repositories
    sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
    sudo dnf install -y https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
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
    echo -e "${BLUE}🐧 Fedora/RHEL Package Installer${NC}"
    
    check_root
    
    # Handle command line parameters
    if [[ $# -gt 0 ]]; then
        case $1 in
            "basic") install_packages "${packages_basic[@]}"; install_flatpak_packages; exit ;;
            "remote") install_packages "${packages_remote[@]}"; install_flatpak_packages; exit ;;
            "dev") install_packages "${packages_dev[@]}"; setup_additional_repos; exit ;;
            "all") 
                install_packages "${packages_basic[@]}"
                install_packages "${packages_remote[@]}"
                install_packages "${packages_dev[@]}"
                install_flatpak_packages
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
                install_flatpak_packages
                break ;;
            [Bb]) 
                install_packages "${packages_remote[@]}"
                install_flatpak_packages
                break ;;
            [Cc]) 
                install_packages "${packages_dev[@]}"
                setup_additional_repos
                break ;;
            [Dd]) 
                install_packages "${packages_basic[@]}"
                install_packages "${packages_remote[@]}"
                install_packages "${packages_dev[@]}"
                install_flatpak_packages
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
