#!/bin/bash

# Fix MOTD Duplicates Script
# Removes duplicate MOTD entries from shell profiles

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

print_status "Checking for duplicate MOTD entries..."

# Function to remove duplicates from a file
remove_duplicates() {
    local file="$1"
    local temp_file="/tmp/motd_fix_$(basename $file)"
    
    if [ -f "$file" ]; then
        # Create a temporary file with unique lines
        awk '!seen[$0]++' "$file" > "$temp_file"
        
        # Check if there were duplicates
        if [ "$(wc -l < "$file")" -gt "$(wc -l < "$temp_file")" ]; then
            print_warning "Found duplicates in $file, removing..."
            sudo cp "$temp_file" "$file"
            print_success "Duplicates removed from $file"
        else
            print_status "No duplicates found in $file"
        fi
        
        rm -f "$temp_file"
    fi
}

# Check and fix /etc/profile
print_status "Checking /etc/profile..."
remove_duplicates "/etc/profile"

# Check and fix user's bash profile
print_status "Checking ~/.bashrc..."
remove_duplicates "$HOME/.bashrc"

# Check and fix user's zsh profile
if [ -f "$HOME/.zshrc" ]; then
    print_status "Checking ~/.zshrc..."
    remove_duplicates "$HOME/.zshrc"
fi

# Check and fix SSH rc
if [ -f "/etc/ssh/sshrc" ]; then
    print_status "Checking /etc/ssh/sshrc..."
    remove_duplicates "/etc/ssh/sshrc"
fi

# Show current MOTD entries
print_status "Current MOTD entries found:"
echo "--- /etc/profile ---"
grep -n "motd" /etc/profile 2>/dev/null || echo "No MOTD entries found"

echo "--- ~/.bashrc ---"
grep -n "motd" ~/.bashrc 2>/dev/null || echo "No MOTD entries found"

if [ -f "$HOME/.zshrc" ]; then
    echo "--- ~/.zshrc ---"
    grep -n "motd" ~/.zshrc 2>/dev/null || echo "No MOTD entries found"
fi

if [ -f "/etc/ssh/sshrc" ]; then
    echo "--- /etc/ssh/sshrc ---"
    grep -n "motd" /etc/ssh/sshrc 2>/dev/null || echo "No MOTD entries found"
fi

print_success "MOTD duplicate check completed!"
print_status "If you see multiple entries above, you may want to manually remove the duplicates." 