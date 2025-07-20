#!/bin/bash

# Fix Broken Profile Scripts
# Fixes syntax errors in /etc/profile and ~/.bashrc caused by MOTD installation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_status "Fixing broken profile scripts..."

# Function to backup and fix a file
fix_file() {
    local file="$1"
    local backup_file="${file}.backup.$(date +%Y%m%d_%H%M%S)"
    
    if [ -f "$file" ]; then
        print_status "Fixing $file..."
        
        # Create backup
        sudo cp "$file" "$backup_file"
        print_status "Backup created: $backup_file"
        
        # Remove only the problematic MOTD lines that are causing syntax errors
        if [ "$file" = "/etc/profile" ]; then
            # Remove only the specific MOTD command lines that are malformed
            sudo sed -i '/^[[:space:]]*\/opt\/motd\.dynamic\/motd-env\/bin\/python/d' "$file"
            sudo sed -i '/^[[:space:]]*python3.*motd\.dynamic/d' "$file"
            # Remove any orphaned 'done' statements that might have been created
            sudo sed -i '/^[[:space:]]*done[[:space:]]*$/d' "$file"
        else
            # Remove only the specific MOTD command lines from user files
            sed -i '/^[[:space:]]*\/opt\/motd\.dynamic\/motd-env\/bin\/python/d' "$file"
            sed -i '/^[[:space:]]*python3.*motd\.dynamic/d' "$file"
        fi
        
        # Test the file for syntax errors
        if bash -n "$file" 2>/dev/null; then
            print_success "$file syntax is now valid"
        else
            print_warning "$file may still have syntax issues, check manually"
        fi
    else
        print_warning "$file does not exist, skipping"
    fi
}

# Fix /etc/profile
fix_file "/etc/profile"

# Fix user's bashrc
fix_file "$HOME/.bashrc"

# Fix user's zshrc if it exists
if [ -f "$HOME/.zshrc" ]; then
    fix_file "$HOME/.zshrc"
fi

print_success "Profile script fixes completed!"
print_status "You may need to restart your shell or logout/login for changes to take effect."
print_warning "If you still see syntax errors, check the backup files and fix manually." 