#!/bin/bash

# Diagnose Profile Issues Script
# Shows exactly what's wrong with profile files without making changes

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

print_status "Diagnosing profile script issues..."

# Function to analyze a file
analyze_file() {
    local file="$1"
    
    if [ -f "$file" ]; then
        print_status "Analyzing $file..."
        
        # Check for syntax errors
        if bash -n "$file" 2>/dev/null; then
            print_success "$file has valid syntax"
        else
            print_error "$file has syntax errors"
            echo "Syntax check output:"
            bash -n "$file" 2>&1 | head -10
        fi
        
        # Show MOTD-related lines
        echo
        print_status "MOTD-related lines in $file:"
        if grep -n "motd" "$file" 2>/dev/null; then
            grep -n "motd" "$file"
        else
            echo "No MOTD-related lines found"
        fi
        
        # Show lines around the error (if it's a known error line)
        echo
        print_status "Lines around potential error areas:"
        if [ "$file" = "/etc/profile" ]; then
            echo "Lines 20-25 of /etc/profile:"
            sed -n '20,25p' "$file" 2>/dev/null || echo "Cannot read lines 20-25"
        fi
        
        if [ "$file" = "$HOME/.bashrc" ]; then
            echo "Lines 35-40 of ~/.bashrc:"
            sed -n '35,40p' "$file" 2>/dev/null || echo "Cannot read lines 35-40"
        fi
        
        echo
        echo "----------------------------------------"
    else
        print_warning "$file does not exist"
    fi
}

# Analyze /etc/profile
analyze_file "/etc/profile"

# Analyze user's bashrc
analyze_file "$HOME/.bashrc"

# Analyze user's zshrc if it exists
if [ -f "$HOME/.zshrc" ]; then
    analyze_file "$HOME/.zshrc"
fi

print_status "Diagnosis completed!"
print_status "Review the output above to understand what's causing the syntax errors."
print_warning "The issue is likely that MOTD commands were inserted in the middle of existing shell constructs." 