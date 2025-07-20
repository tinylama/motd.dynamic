#!/bin/bash

# Modern MOTD Installation Script
# For Ubuntu/Debian systems

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
sudo apt install -y python3 python3-pip python3-venv git curl

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

# Step 4: Optional Docker installation
read -p "Do you want to install Docker for container monitoring? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Installing Docker..."
    sudo apt install -y docker.io
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
    print_warning "You'll need to logout and login again for Docker permissions to take effect"
fi

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

# Step 6: Try to create virtual environment, fallback to system install
print_status "Setting up Python environment..."

# Check if virtual environment creation is possible
if python3 -m venv --help > /dev/null 2>&1; then
    print_status "Creating Python virtual environment..."
    python3 -m venv motd-env
    source motd-env/bin/activate
    
    # Install Python dependencies
    print_status "Installing Python dependencies in virtual environment..."
    pip install --upgrade pip
    pip install -r requirements.txt
    
    # Test if installation was successful
    if python -c "import rich, psutil, pyfiglet, requests, distro" 2>/dev/null; then
        print_success "Virtual environment setup successful!"
        MOTD_COMMAND="$INSTALL_DIR/motd-env/bin/python $INSTALL_DIR/motd.dynamic"
        USE_VENV=true
    else
        print_warning "Virtual environment setup failed, falling back to system Python..."
        USE_VENV=false
    fi
else
    print_warning "Virtual environment not available, using system Python..."
    USE_VENV=false
fi

# Fallback to system Python if virtual environment failed
if [ "$USE_VENV" = false ]; then
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

# Step 9: Setup auto-display options
echo
print_status "Choose how you want to display the MOTD:"
echo "1) System-wide (all users)"
echo "2) Current user only"
echo "3) SSH login only"
echo "4) Manual setup (skip auto-setup)"
read -p "Enter your choice (1-4): " -n 1 -r
echo

case $REPLY in
    1)
        print_status "Setting up system-wide MOTD..."
        echo "$MOTD_COMMAND" | sudo tee -a /etc/profile > /dev/null
        sudo chmod -x /etc/update-motd.d/* 2>/dev/null || true
        print_success "System-wide MOTD configured"
        ;;
    2)
        print_status "Setting up user-specific MOTD..."
        if [ -n "$ZSH_VERSION" ] || [ -f "$HOME/.zshrc" ]; then
            echo "$MOTD_COMMAND" >> ~/.zshrc
            print_success "Added to ~/.zshrc"
        else
            echo "$MOTD_COMMAND" >> ~/.bashrc
            print_success "Added to ~/.bashrc"
        fi
        ;;
    3)
        print_status "Setting up SSH-only MOTD..."
        sudo tee /etc/ssh/sshrc > /dev/null << EOF
#!/bin/bash
$MOTD_COMMAND
EOF
        sudo chmod +x /etc/ssh/sshrc
        
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
        print_success "SSH-only MOTD configured"
        ;;
    4)
        print_status "Skipping auto-setup. You can manually add the following command to your shell profile:"
        echo "$MOTD_COMMAND"
        ;;
    *)
        print_warning "Invalid choice. Skipping auto-setup."
        ;;
esac

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
if [ "$USE_VENV" = true ]; then
    echo "  - Virtual environment: $INSTALL_DIR/motd-env/"
else
    echo "  - System Python installation"
fi
echo
print_status "Next steps:"
echo "  - Customize your banner text in config.json"
echo "  - Adjust color themes and thresholds as needed"
echo "  - Enable weather integration by getting an API key from OpenWeatherMap"
echo "  - If you installed Docker, logout and login again for permissions"
echo
print_success "Enjoy your new modern MOTD! 🎉" 