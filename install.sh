#!/bin/bash

# Modern MOTD Installation Script
# For Ubuntu/Debian systems - Automated installation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Function to check and remove existing MOTD entries
check_and_remove_motd_duplicates() {
    print_status "Checking for existing MOTD entries and removing duplicates..."
    
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
    
    # Remove any existing MOTD entries
    print_status "Removing existing MOTD entries..."
    
    # Remove from /etc/profile
    if [ -f "/etc/profile" ]; then
        sudo sed -i '/motd\.dynamic/d' /etc/profile
    fi
    
    # Remove from ~/.bashrc
    if [ -f "$HOME/.bashrc" ]; then
        sed -i '/motd\.dynamic/d' ~/.bashrc
    fi
    
    # Remove from ~/.zshrc
    if [ -f "$HOME/.zshrc" ]; then
        sed -i '/motd\.dynamic/d' ~/.zshrc
    fi
    
    # Remove from /etc/ssh/sshrc
    if [ -f "/etc/ssh/sshrc" ]; then
        sudo sed -i '/motd\.dynamic/d' /etc/ssh/sshrc
    fi
    
    print_success "Existing MOTD entries cleaned up"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_error "This script should not be run as root"
    exit 1
fi

print_status "Starting Modern MOTD installation..."

# Step 1: Update system
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Step 2: Install Python and dependencies
print_status "Installing Python 3 and pip..."
sudo apt install -y python3 python3-pip git curl

# Step 3: Install system dependencies
print_status "Installing system dependencies..."
sudo apt install -y \
    figlet \
    lsb-release \
    net-tools \
    htop \
    curl \
    wget \
    systemd

# Step 4: Check and remove existing MOTD entries
check_and_remove_motd_duplicates

# Step 5: Setup MOTD directory
INSTALL_DIR="/opt/motd.dynamic"
print_status "Setting up MOTD in $INSTALL_DIR..."

if [ -d "$INSTALL_DIR" ]; then
    print_warning "Directory $INSTALL_DIR already exists. Backing up..."
    sudo mv "$INSTALL_DIR" "$INSTALL_DIR.backup.$(date +%Y%m%d_%H%M%S)"
fi

sudo mkdir -p "$INSTALL_DIR"
sudo chown -R $USER:$USER "$INSTALL_DIR"

# Copy files to install directory
cp motd.dynamic "$INSTALL_DIR/"
cp requirements.txt "$INSTALL_DIR/"
cp config.json "$INSTALL_DIR/"
cp README.md "$INSTALL_DIR/"

cd "$INSTALL_DIR"

# Step 6: Install Python dependencies system-wide
print_status "Installing Python dependencies system-wide..."
sudo pip3 install --upgrade pip
sudo pip3 install -r requirements.txt

# Test system installation
if python3 -c "import rich, psutil, pyfiglet, requests, distro" 2>/dev/null; then
    print_success "System Python setup successful!"
    MOTD_COMMAND="python3 $INSTALL_DIR/motd.dynamic"
else
    print_error "Failed to install Python dependencies. Please check your Python installation."
    exit 1
fi

# Step 7: Make executable
chmod +x motd.dynamic

# Step 8: Test installation
print_status "Testing MOTD installation..."
if $MOTD_COMMAND; then
    print_success "MOTD test successful!"
else
    print_error "MOTD test failed. Please check the installation."
    exit 1
fi

# Step 9: Setup system-wide MOTD (no choices)
print_status "Setting up system-wide MOTD..."
echo "$MOTD_COMMAND" | sudo tee -a /etc/profile > /dev/null

# Disable default MOTD
sudo chmod -x /etc/update-motd.d/* 2>/dev/null || true

# Configure SSH to not show default MOTD
if sudo grep -q "PrintMotd" /etc/ssh/sshd_config; then
    sudo sed -i 's/.*PrintMotd.*/PrintMotd no/' /etc/ssh/sshd_config
else
    echo "PrintMotd no" | sudo tee -a /etc/ssh/sshd_config > /dev/null
fi

if sudo grep -q "PrintLastLog" /etc/ssh/sshd_config; then
    sudo sed -i 's/.*PrintLastLog.*/PrintLastLog no/' /etc/ssh/sshd_config
else
    echo "PrintLastLog no" | sudo tee -a /etc/ssh/sshd_config > /dev/null
fi

sudo systemctl restart sshd
print_success "System-wide MOTD configured"

# Step 10: Configuration instructions
echo
print_success "Installation completed successfully!"
echo
print_status "Configuration:"
echo "  - Edit $INSTALL_DIR/config.json to customize the MOTD"
echo "  - Banner text, colors, and features can all be configured"
echo "  - Run '$MOTD_COMMAND' to test changes"
echo
print_status "Environment used:"
echo "  - System Python installation"
echo
print_status "Next steps:"
echo "  - Customize your banner text in config.json"
echo "  - Adjust color themes and thresholds as needed"
echo "  - Enable weather integration by getting an API key from OpenWeatherMap"
echo
print_success "Enjoy your new modern MOTD! 🎉" 