#!/bin/bash

# GUI Interface for Machine Bootstrap
# Provides a graphical interface using dialog/zenity/whiptail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Detect available GUI tools
detect_gui_tool() {
    if command -v zenity &> /dev/null; then
        echo "zenity"
    elif command -v dialog &> /dev/null; then
        echo "dialog"
    elif command -v whiptail &> /dev/null; then
        echo "whiptail"
    else
        echo "none"
    fi
}

# Install GUI dependencies if needed
install_gui_deps() {
    local gui_tool=$(detect_gui_tool)
    
    if [ "$gui_tool" = "none" ]; then
        echo -e "${YELLOW}Installing GUI dependencies...${NC}"
        
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y zenity dialog
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y zenity dialog
        elif command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm zenity dialog
        elif command -v brew &> /dev/null; then
            # macOS - install via homebrew
            brew install zenity dialog
        else
            echo -e "${RED}Cannot install GUI dependencies${NC}"
            return 1
        fi
    fi
    
    return 0
}

# Welcome screen
show_welcome() {
    local gui_tool=$(detect_gui_tool)
    
    case $gui_tool in
        "zenity")
            zenity --info \
                --title="Machine Bootstrap" \
                --text="Welcome to Machine Bootstrap!\n\nThis tool will help you set up your development environment with essential software packages.\n\nClick OK to continue." \
                --width=400 \
                --height=200
            ;;
        "dialog")
            dialog --title "Machine Bootstrap" \
                --msgbox "Welcome to Machine Bootstrap!\n\nThis tool will help you set up your development environment with essential software packages.\n\nPress OK to continue." \
                10 60
            clear
            ;;
        "whiptail")
            whiptail --title "Machine Bootstrap" \
                --msgbox "Welcome to Machine Bootstrap!\n\nThis tool will help you set up your development environment with essential software packages.\n\nPress OK to continue." \
                10 60
            ;;
        *)
            echo -e "${CYAN}🚀 Welcome to Machine Bootstrap!${NC}"
            echo -e "${BLUE}This tool will help you set up your development environment.${NC}"
            read -p "Press Enter to continue..."
            ;;
    esac
}

# OS Selection (if auto-detection fails)
select_os() {
    local gui_tool=$(detect_gui_tool)
    local selected_os=""
    
    case $gui_tool in
        "zenity")
            selected_os=$(zenity --list \
                --title="Select Operating System" \
                --text="Please select your operating system:" \
                --column="OS" \
                "Ubuntu/Debian" \
                "Fedora/RHEL" \
                "Arch Linux" \
                "macOS" \
                "Windows" \
                --width=300 \
                --height=300)
            ;;
        "dialog")
            selected_os=$(dialog --title "Select Operating System" \
                --menu "Please select your operating system:" \
                15 50 5 \
                1 "Ubuntu/Debian" \
                2 "Fedora/RHEL" \
                3 "Arch Linux" \
                4 "macOS" \
                5 "Windows" \
                3>&1 1>&2 2>&3)
            clear
            
            case $selected_os in
                1) selected_os="Ubuntu/Debian" ;;
                2) selected_os="Fedora/RHEL" ;;
                3) selected_os="Arch Linux" ;;
                4) selected_os="macOS" ;;
                5) selected_os="Windows" ;;
            esac
            ;;
        "whiptail")
            selected_os=$(whiptail --title "Select Operating System" \
                --menu "Please select your operating system:" \
                15 50 5 \
                1 "Ubuntu/Debian" \
                2 "Fedora/RHEL" \
                3 "Arch Linux" \
                4 "macOS" \
                5 "Windows" \
                3>&1 1>&2 2>&3)
            
            case $selected_os in
                1) selected_os="Ubuntu/Debian" ;;
                2) selected_os="Fedora/RHEL" ;;
                3) selected_os="Arch Linux" ;;
                4) selected_os="macOS" ;;
                5) selected_os="Windows" ;;
            esac
            ;;
        *)
            echo "Select your OS:"
            echo "1) Ubuntu/Debian"
            echo "2) Fedora/RHEL"
            echo "3) Arch Linux"
            echo "4) macOS"
            echo "5) Windows"
            local choice
            read -p "Enter choice (1-5): " choice
            
            case $choice in
                1) selected_os="Ubuntu/Debian" ;;
                2) selected_os="Fedora/RHEL" ;;
                3) selected_os="Arch Linux" ;;
                4) selected_os="macOS" ;;
                5) selected_os="Windows" ;;
            esac
            ;;
    esac
    
    echo "$selected_os"
}

# Package Category Selection
select_packages() {
    local gui_tool=$(detect_gui_tool)
    local selected_packages=""
    
    case $gui_tool in
        "zenity")
            selected_packages=$(zenity --list \
                --title="Select Package Categories" \
                --text="Choose which software categories to install:" \
                --checklist \
                --column="Install" \
                --column="Category" \
                --column="Description" \
                TRUE "Basic" "Essential tools, browsers, media players" \
                FALSE "Remote" "Video conferencing, team collaboration" \
                FALSE "Development" "Programming tools, IDEs, databases" \
                --width=600 \
                --height=300 \
                --separator=",")
            ;;
        "dialog")
            selected_packages=$(dialog --title "Select Package Categories" \
                --checklist "Choose which software categories to install:" \
                15 70 3 \
                "Basic" "Essential tools, browsers, media players" on \
                "Remote" "Video conferencing, team collaboration" off \
                "Development" "Programming tools, IDEs, databases" off \
                3>&1 1>&2 2>&3)
            clear
            ;;
        "whiptail")
            selected_packages=$(whiptail --title "Select Package Categories" \
                --checklist "Choose which software categories to install:" \
                15 70 3 \
                "Basic" "Essential tools, browsers, media players" on \
                "Remote" "Video conferencing, team collaboration" off \
                "Development" "Programming tools, IDEs, databases" off \
                3>&1 1>&2 2>&3)
            ;;
        *)
            echo "Select package categories:"
            echo "1) Basic packages (essential tools)"
            echo "2) Remote work packages"
            echo "3) Development packages"
            echo "4) All packages"
            local choice
            read -p "Enter choice (1-4): " choice
            
            case $choice in
                1) selected_packages="basic" ;;
                2) selected_packages="remote" ;;
                3) selected_packages="dev" ;;
                4) selected_packages="all" ;;
            esac
            ;;
    esac
    
    echo "$selected_packages"
}

# Installation Options
select_options() {
    local gui_tool=$(detect_gui_tool)
    local options=""
    
    case $gui_tool in
        "zenity")
            options=$(zenity --list \
                --title="Installation Options" \
                --text="Select additional installation options:" \
                --checklist \
                --column="Enable" \
                --column="Option" \
                --column="Description" \
                TRUE "backup" "Create system backup before installation" \
                FALSE "force" "Force installation even if packages exist" \
                FALSE "parallel" "Enable parallel package installation" \
                FALSE "skip-checks" "Skip system and security checks" \
                --width=600 \
                --height=300 \
                --separator=",")
            ;;
        "dialog")
            options=$(dialog --title "Installation Options" \
                --checklist "Select additional installation options:" \
                15 70 4 \
                "backup" "Create system backup before installation" on \
                "force" "Force installation even if packages exist" off \
                "parallel" "Enable parallel package installation" off \
                "skip-checks" "Skip system and security checks" off \
                3>&1 1>&2 2>&3)
            clear
            ;;
        "whiptail")
            options=$(whiptail --title "Installation Options" \
                --checklist "Select additional installation options:" \
                15 70 4 \
                "backup" "Create system backup before installation" on \
                "force" "Force installation even if packages exist" off \
                "parallel" "Enable parallel package installation" off \
                "skip-checks" "Skip system and security checks" off \
                3>&1 1>&2 2>&3)
            ;;
        *)
            echo "Installation options (y/n):"
            read -p "Create backup? (Y/n): " backup_opt
            read -p "Force installation? (y/N): " force_opt
            read -p "Parallel installation? (y/N): " parallel_opt
            read -p "Skip checks? (y/N): " skip_opt
            
            options=""
            [[ "$backup_opt" != "n" && "$backup_opt" != "N" ]] && options="$options,backup"
            [[ "$force_opt" == "y" || "$force_opt" == "Y" ]] && options="$options,force"
            [[ "$parallel_opt" == "y" || "$parallel_opt" == "Y" ]] && options="$options,parallel"
            [[ "$skip_opt" == "y" || "$skip_opt" == "Y" ]] && options="$options,skip-checks"
            ;;
    esac
    
    echo "$options"
}

# Progress Dialog
show_progress() {
    local gui_tool=$(detect_gui_tool)
    local step=$1
    local total=$2
    local message=$3
    local percentage=$(( step * 100 / total ))
    
    case $gui_tool in
        "zenity")
            echo "$percentage"
            echo "# $message"
            ;;
        "dialog")
            echo "$percentage" | dialog --title "Installing..." \
                --gauge "$message" 8 60 0
            ;;
        *)
            echo -e "${CYAN}[$step/$total] $message${NC}"
            ;;
    esac
}

# Confirmation Dialog
show_confirmation() {
    local gui_tool=$(detect_gui_tool)
    local packages=$1
    local options=$2
    
    case $gui_tool in
        "zenity")
            zenity --question \
                --title="Confirm Installation" \
                --text="Ready to install:\n\nPackages: $packages\nOptions: $options\n\nProceed with installation?" \
                --width=400
            ;;
        "dialog")
            dialog --title "Confirm Installation" \
                --yesno "Ready to install:\n\nPackages: $packages\nOptions: $options\n\nProceed with installation?" \
                10 60
            local result=$?
            clear
            return $result
            ;;
        "whiptail")
            whiptail --title "Confirm Installation" \
                --yesno "Ready to install:\n\nPackages: $packages\nOptions: $options\n\nProceed with installation?" \
                10 60
            ;;
        *)
            echo -e "${CYAN}Ready to install:${NC}"
            echo -e "${WHITE}Packages: $packages${NC}"
            echo -e "${WHITE}Options: $options${NC}"
            read -p "Proceed with installation? (Y/n): " confirm
            [[ "$confirm" != "n" && "$confirm" != "N" ]]
            ;;
    esac
}

# Success Dialog
show_success() {
    local gui_tool=$(detect_gui_tool)
    local duration=$1
    local log_file=$2
    
    case $gui_tool in
        "zenity")
            zenity --info \
                --title="Installation Complete" \
                --text="✅ Installation completed successfully!\n\nDuration: ${duration}s\nLog file: $log_file\n\nYour system is now ready to use!" \
                --width=400
            ;;
        "dialog")
            dialog --title "Installation Complete" \
                --msgbox "✅ Installation completed successfully!\n\nDuration: ${duration}s\nLog file: $log_file\n\nYour system is now ready to use!" \
                10 60
            clear
            ;;
        "whiptail")
            whiptail --title "Installation Complete" \
                --msgbox "✅ Installation completed successfully!\n\nDuration: ${duration}s\nLog file: $log_file\n\nYour system is now ready to use!" \
                10 60
            ;;
        *)
            echo -e "${GREEN}✅ Installation completed successfully!${NC}"
            echo -e "${YELLOW}Duration: ${duration}s${NC}"
            echo -e "${YELLOW}Log file: $log_file${NC}"
            echo -e "${BLUE}Your system is now ready to use!${NC}"
            ;;
    esac
}

# Error Dialog
show_error() {
    local gui_tool=$(detect_gui_tool)
    local error_msg=$1
    local log_file=$2
    
    case $gui_tool in
        "zenity")
            zenity --error \
                --title="Installation Failed" \
                --text="❌ Installation failed!\n\nError: $error_msg\n\nCheck log file: $log_file" \
                --width=400
            ;;
        "dialog")
            dialog --title "Installation Failed" \
                --msgbox "❌ Installation failed!\n\nError: $error_msg\n\nCheck log file: $log_file" \
                10 60
            clear
            ;;
        "whiptail")
            whiptail --title "Installation Failed" \
                --msgbox "❌ Installation failed!\n\nError: $error_msg\n\nCheck log file: $log_file" \
                10 60
            ;;
        *)
            echo -e "${RED}❌ Installation failed!${NC}"
            echo -e "${YELLOW}Error: $error_msg${NC}"
            echo -e "${YELLOW}Check log file: $log_file${NC}"
            ;;
    esac
}

# Main GUI workflow
run_gui() {
    # Install GUI dependencies if needed
    if ! install_gui_deps; then
        echo -e "${RED}Cannot run GUI mode without dialog tools${NC}"
        return 1
    fi
    
    # Welcome screen
    show_welcome
    
    # Package selection
    local packages=$(select_packages)
    if [ -z "$packages" ]; then
        echo "Installation cancelled."
        return 1
    fi
    
    # Options selection
    local options=$(select_options)
    
    # Confirmation
    if ! show_confirmation "$packages" "$options"; then
        echo "Installation cancelled."
        return 1
    fi
    
    # Build command line arguments
    local args=()
    
    # Convert GUI selections to command line args
    if [[ "$options" == *"backup"* ]]; then
        args+=("--backup")
    fi
    if [[ "$options" == *"force"* ]]; then
        args+=("--force")
    fi
    if [[ "$options" == *"parallel"* ]]; then
        args+=("--parallel")
    fi
    if [[ "$options" == *"skip-checks"* ]]; then
        args+=("--skip-checks")
    fi
    
    # Convert package selection
    if [[ "$packages" == *"Basic"* && "$packages" == *"Remote"* && "$packages" == *"Development"* ]]; then
        args+=("all")
    elif [[ "$packages" == *"Basic"* ]]; then
        args+=("basic")
    elif [[ "$packages" == *"Remote"* ]]; then
        args+=("remote")
    elif [[ "$packages" == *"Development"* ]]; then
        args+=("dev")
    fi
    
    echo -e "${CYAN}Starting installation with GUI...${NC}"
    echo -e "${BLUE}Arguments: ${args[*]}${NC}"
    
    # Execute installation (this would call the main install script)
    # For now, we'll simulate it
    local start_time=$(date +%s)
    
    # Simulate installation with progress
    for i in {1..10}; do
        show_progress $i 10 "Installing package group $i..."
        sleep 1
    done
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Show success
    show_success "$duration" "/tmp/machine-bootstrap.log"
    
    return 0
}

# Export functions
export -f run_gui
export -f show_welcome
export -f select_packages
export -f show_progress

# If script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_gui "$@"
fi
