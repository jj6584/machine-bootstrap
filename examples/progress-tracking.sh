#!/bin/bash

# Progress tracking system
TOTAL_STEPS=0
CURRENT_STEP=0
START_TIME=$(date +%s)

# Progress bar function
show_progress() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((current * width / total))
    local remaining=$((width - completed))
    
    printf "\r["
    printf "%${completed}s" | tr ' ' '█'
    printf "%${remaining}s" | tr ' ' '░'
    printf "] %d%% (%d/%d)" $percentage $current $total
}

# Step tracking
step() {
    local description=$1
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo -e "\n${CYAN}[$CURRENT_STEP/$TOTAL_STEPS] $description${NC}"
    show_progress $CURRENT_STEP $TOTAL_STEPS
}

# Analytics (optional, privacy-respecting)
send_analytics() {
    local event=$1
    local os_type=$2
    
    # Only if user opted in
    if [ -f "$HOME/.machine-bootstrap-analytics-ok" ]; then
        curl -s -X POST "https://your-analytics-endpoint.com/event" \
            -H "Content-Type: application/json" \
            -d "{\"event\":\"$event\",\"os\":\"$os_type\",\"version\":\"$SCRIPT_VERSION\"}" \
            &> /dev/null || true
    fi
}

# Usage example
calculate_total_steps() {
    TOTAL_STEPS=10  # Calculate based on selected packages
}

run_installation() {
    calculate_total_steps
    
    step "Updating package lists"
    # ... installation code ...
    
    step "Installing basic packages"
    # ... installation code ...
    
    step "Setting up repositories"
    # ... installation code ...
}
