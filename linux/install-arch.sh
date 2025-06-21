#!/bin/bash

# Arch Linux Package Installer
# Compatible with Arch Linux and Arch-based distributions

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Package arrays
declare -a packages_basic=(
    "curl" "wget" "git" "vim" "firefox" "vlc" "base-devel"
)

declare -a packages_remote=(
    "remmina" "filezilla" "thunderbird"
)

declare -a packages_dev=(
    "nodejs" "npm" "python" "python-pip" "docker" 
    "docker-compose" "jdk11-openjdk" "mysql" "postgresql" "redis"
)

# AUR packages (requires yay or another AUR helper)
declare -a aur_packages=(
    "google-chrome" "discord" "visual-studio-code-bin" 
    "teams" "zoom" "postman-bin" "steam"
)

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        echo -e "${RED}❌ This script should not be run as root${NC}"
        exit 1
    fi
}

# Function to install yay (AUR helper)
install_yay() {
    if ! command -v yay &> /dev/null; then
        echo -e "${YELLOW}📦 Installing yay (AUR helper)...${NC}"
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay
        makepkg -si --noconfirm
        cd -
        rm -rf /tmp/yay
    else
        echo -e "${GREEN}✅ yay already installed${NC}"
    fi
}

# Function to install packages
install_packages() {
    local packages=("$@")
    echo -e "${YELLOW}🔄 Updating package database...${NC}"
    sudo pacman -Sy
    
    echo -e "${CYAN}📦 Installing ${#packages[@]} packages...${NC}"
    for package in "${packages[@]}"; do
        echo -e "${BLUE}Installing $package...${NC}"
        sudo pacman -S --noconfirm "$package"
    done
}

# Function to install AUR packages
install_aur_packages() {
    echo -e "${CYAN}📦 Installing AUR packages...${NC}"
    
    install_yay
    
    for package in "${aur_packages[@]}"; do
        echo -e "${BLUE}Installing $package from AUR...${NC}"
        yay -S --noconfirm "$package"
    done
}

# Function to setup additional services
setup_services() {
    echo -e "${YELLOW}🔧 Setting up services...${NC}"
    
    # Enable Docker
    if command -v docker &> /dev/null; then
        sudo systemctl enable --now docker
        sudo usermod -aG docker $USER
    fi
    
    # Enable database services if installed
    if command -v mysql &> /dev/null; then
        sudo systemctl enable --now mysqld
    fi
    
    if command -v postgresql &> /dev/null; then
        sudo systemctl enable --now postgresql
    fi
    
    if command -v redis-server &> /dev/null; then
        sudo systemctl enable --now redis
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
    echo -e "${BLUE}🐧 Arch Linux Package Installer${NC}"
    
    check_root
    
    # Handle command line parameters
    if [[ $# -gt 0 ]]; then
        case $1 in
            "basic") install_packages "${packages_basic[@]}"; install_aur_packages; exit ;;
            "remote") install_packages "${packages_remote[@]}"; install_aur_packages; exit ;;
            "dev") install_packages "${packages_dev[@]}"; setup_services; exit ;;
            "all") 
                install_packages "${packages_basic[@]}"
                install_packages "${packages_remote[@]}"
                install_packages "${packages_dev[@]}"
                install_aur_packages
                setup_services
                exit ;;
        esac
    fi
    
    # Interactive menu
    while true; do
        show_menu
        read -p "Enter your choice: " choice
        
        case $choice in
            [Aa]) 
                install_packages "${packages_basic[@]}"
                install_aur_packages
                break ;;
            [Bb]) 
                install_packages "${packages_remote[@]}"
                install_aur_packages
                break ;;
            [Cc]) 
                install_packages "${packages_dev[@]}"
                setup_services
                break ;;
            [Dd]) 
                install_packages "${packages_basic[@]}"
                install_packages "${packages_remote[@]}"
                install_packages "${packages_dev[@]}"
                install_aur_packages
                setup_services
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
