#!/bin/bash

# macOS Package Installer
# Compatible with macOS using Homebrew

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to install Homebrew
install_homebrew() {
    if ! command -v brew &> /dev/null; then
        echo -e "${YELLOW}🍺 Installing Homebrew...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for Apple Silicon Macs
        if [[ $(uname -m) == "arm64" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    else
        echo -e "${GREEN}✅ Homebrew already installed${NC}"
        brew update
    fi
}

# Package arrays for Homebrew formulae (command line tools)
declare -a formulae_basic=(
    "curl" "wget" "git" "vim" "node" "python"
)

declare -a formulae_dev=(
    "docker" "docker-compose" "mysql" "postgresql" "redis"
    "openjdk@11" "maven" "gradle"
)

# Package arrays for Homebrew casks (GUI applications)
declare -a casks_basic=(
    "firefox" "vlc" "discord" "steam" 
    "the-unarchiver" "adobe-acrobat-reader"
)

declare -a casks_remote=(
    "zoom" "microsoft-teams" "teamviewer" "google-chrome" 
    "dropbox" "slack" "remote-desktop-manager"
)

declare -a casks_dev=(
    "visual-studio-code" "postman" "docker" "iterm2"
    "jetbrains-toolbox" "github-desktop" "sourcetree"
)

# Function to install packages
install_formulae() {
    local packages=("$@")
    echo -e "${CYAN}📦 Installing ${#packages[@]} formulae...${NC}"
    
    for package in "${packages[@]}"; do
        echo -e "${BLUE}Installing formula: $package...${NC}"
        brew install "$package"
    done
}

install_casks() {
    local packages=("$@")
    echo -e "${CYAN}📦 Installing ${#packages[@]} casks...${NC}"
    
    for package in "${packages[@]}"; do
        echo -e "${BLUE}Installing cask: $package...${NC}"
        brew install --cask "$package" 2>/dev/null || echo -e "${YELLOW}⚠️ Skipped $package (may already be installed)${NC}"
    done
}

# Function to setup additional services
setup_services() {
    echo -e "${YELLOW}🔧 Setting up services...${NC}"
    
    # Start MySQL if installed
    if brew list mysql &> /dev/null; then
        brew services start mysql
    fi
    
    # Start PostgreSQL if installed
    if brew list postgresql &> /dev/null; then
        brew services start postgresql
    fi
    
    # Start Redis if installed
    if brew list redis &> /dev/null; then
        brew services start redis
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
    echo -e "${BLUE}🍎 macOS Package Installer${NC}"
    
    install_homebrew
    
    # Handle command line parameters
    if [[ $# -gt 0 ]]; then
        case $1 in
            "basic") 
                install_formulae "${formulae_basic[@]}"
                install_casks "${casks_basic[@]}"
                exit ;;
            "remote") 
                install_casks "${casks_remote[@]}"
                exit ;;
            "dev") 
                install_formulae "${formulae_dev[@]}"
                install_casks "${casks_dev[@]}"
                setup_services
                exit ;;
            "all") 
                install_formulae "${formulae_basic[@]}"
                install_formulae "${formulae_dev[@]}"
                install_casks "${casks_basic[@]}"
                install_casks "${casks_remote[@]}"
                install_casks "${casks_dev[@]}"
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
                install_formulae "${formulae_basic[@]}"
                install_casks "${casks_basic[@]}"
                break ;;
            [Bb]) 
                install_casks "${casks_remote[@]}"
                break ;;
            [Cc]) 
                install_formulae "${formulae_dev[@]}"
                install_casks "${casks_dev[@]}"
                setup_services
                break ;;
            [Dd]) 
                install_formulae "${formulae_basic[@]}"
                install_formulae "${formulae_dev[@]}"
                install_casks "${casks_basic[@]}"
                install_casks "${casks_remote[@]}"
                install_casks "${casks_dev[@]}"
                setup_services
                break ;;
            [Ee]) exit ;;
            *) echo -e "${RED}❌ Invalid input. Please select A, B, C, D, or E.${NC}" ;;
        esac
    done
    
    echo -e "${GREEN}✅ Installation complete!${NC}"
    echo -e "${YELLOW}Note: Some applications may require additional setup.${NC}"
}

# Run main function
main "$@"
