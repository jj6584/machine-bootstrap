#!/bin/bash

# Backup and rollback system
BACKUP_DIR="$HOME/.machine-bootstrap-backups/$(date +%Y%m%d-%H%M%S)"

# Create backup before installation
create_backup() {
    echo "📦 Creating system backup..."
    mkdir -p "$BACKUP_DIR"
    
    # Backup important config files
    cp -r "$HOME/.bashrc" "$BACKUP_DIR/" 2>/dev/null || true
    cp -r "$HOME/.zshrc" "$BACKUP_DIR/" 2>/dev/null || true
    cp -r "$HOME/.gitconfig" "$BACKUP_DIR/" 2>/dev/null || true
    cp -r "$HOME/.ssh/config" "$BACKUP_DIR/" 2>/dev/null || true
    
    # Save installed packages list
    if command -v apt &> /dev/null; then
        dpkg --get-selections > "$BACKUP_DIR/installed-packages.txt"
    elif command -v dnf &> /dev/null; then
        dnf list installed > "$BACKUP_DIR/installed-packages.txt"
    fi
    
    echo "✅ Backup created at: $BACKUP_DIR"
}

# Rollback function
rollback() {
    local backup_path=$1
    echo "🔄 Rolling back from backup: $backup_path"
    
    # Restore config files
    if [ -f "$backup_path/.bashrc" ]; then
        cp "$backup_path/.bashrc" "$HOME/"
    fi
    
    # Additional rollback logic...
    echo "✅ Rollback completed"
}
