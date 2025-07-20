# Modern Dynamic MOTD - Python 3 Enhanced

A stunning, modern Message of the Day (MOTD) script for Linux systems, completely rewritten with Python 3 and enhanced with beautiful visuals, performance optimizations, and extensive system monitoring capabilities.

## ✨ Features

### Core System Information
- 🖥️ **System Overview**: Uptime, boot time, OS information, kernel version
- 🔧 **CPU Monitoring**: Real-time CPU usage with color-coded warnings
- 🧠 **Memory Analytics**: RAM usage with visual indicators
- 💾 **Disk Usage**: All mounted filesystems with usage percentages
- 🌐 **Network Information**: All network interfaces + public IP detection
- 👥 **User Sessions**: Currently logged-in users and session counts

### Enhanced Modern Features
- 🐳 **Docker Integration**: Container status and running services
- ⚙️ **SystemD Monitoring**: Failed service detection and alerts
- 📦 **Package Updates**: Available system updates (APT/DNF support)
- 🔒 **SSL Certificate Monitoring**: Certificate expiration warnings
- 📊 **Performance Metrics**: Load averages and process counts
- 💭 **Daily Quotes**: Inspirational tech quotes

### Visual Excellence
- 🎨 **Rich Terminal UI**: Beautiful tables, panels, and layouts using Rich library
- 🌈 **Color-Coded Status**: Green/Yellow/Red indicators for system health
- 📏 **Responsive Design**: Adapts to terminal width
- 🎭 **ASCII Art Banners**: Multiple figlet fonts with random selection
- 📱 **Modern Icons**: Emoji icons for better visual categorization

### Performance & Reliability
- ⚡ **Async Operations**: Non-blocking network requests
- 🧵 **Threaded Execution**: Parallel information gathering
- 🛡️ **Error Handling**: Graceful degradation if services are unavailable
- ⚙️ **Configurable**: Extensive configuration options
- 🔧 **Modular Design**: Clean, maintainable code structure

## 🚀 Fresh Ubuntu Installation Setup

### Step 1: System Update
```bash
sudo apt update && sudo apt upgrade -y
```

### Step 2: Install Python 3 and pip
```bash
sudo apt install python3 python3-pip python3-venv git curl -y
```

### Step 3: Install System Dependencies
```bash
# Essential tools for enhanced features
sudo apt install -y \
    figlet \
    lsb-release \
    net-tools \
    htop \
    curl \
    wget \
    systemd

# Optional: Docker support (if you want Docker monitoring)
sudo apt install -y docker.io
sudo systemctl enable docker
sudo usermod -aG docker $USER
```

### Step 4: Clone and Setup MOTD
```bash
# Clone the repository
cd /opt
sudo git clone https://github.com/your-repo/motd.dynamic
sudo chown -R $USER:$USER /opt/motd.dynamic
cd /opt/motd.dynamic

# Create virtual environment (recommended)
python3 -m venv motd-env
source motd-env/bin/activate

# Install Python dependencies
pip install -r requirements.txt

# Make executable
chmod +x motd.dynamic
```

### Step 5: Test the MOTD
```bash
# Test run
./motd.dynamic

# If everything works, you should see a beautiful system info display
```

### Step 6: Setup Auto-Display on Login

#### Option A: For all users (system-wide)
```bash
# Add to system profile
echo '/opt/motd.dynamic/motd-env/bin/python /opt/motd.dynamic/motd.dynamic' | sudo tee -a /etc/profile

# Disable default Ubuntu MOTD
sudo chmod -x /etc/update-motd.d/*
```

#### Option B: For specific user
```bash
# Add to user's bash profile
echo '/opt/motd.dynamic/motd-env/bin/python /opt/motd.dynamic/motd.dynamic' >> ~/.bashrc

# Or for zsh users
echo '/opt/motd.dynamic/motd-env/bin/python /opt/motd.dynamic/motd.dynamic' >> ~/.zshrc
```

#### Option C: SSH-only display
```bash
# Create wrapper script
sudo tee /etc/ssh/sshrc > /dev/null << 'EOF'
#!/bin/bash
/opt/motd.dynamic/motd-env/bin/python /opt/motd.dynamic/motd.dynamic
EOF

sudo chmod +x /etc/ssh/sshrc
```

### Step 7: Configure SSH (Optional)
```bash
# Edit SSH config to disable default messages
sudo nano /etc/ssh/sshd_config

# Add or modify these lines:
PrintMotd no
PrintLastLog no

# Restart SSH
sudo systemctl restart sshd
```

## ⚙️ Configuration

Edit the configuration directly in the script by modifying the `MOTDConfig` class:

```python
@dataclass
class MOTDConfig:
    # Display settings
    line_length: int = 100
    banner_text: str = "YOUR-SERVER-NAME"
    
    # Color theme
    color_ok: str = "green"
    color_warn: str = "yellow" 
    color_critical: str = "red"
    
    # Feature toggles
    show_docker: bool = True
    show_systemd: bool = True
    show_weather: bool = False  # Requires API key
    
    # Thresholds
    disk_warn_threshold: int = 70
    memory_warn_threshold: int = 70
    cpu_warn_threshold: int = 70
```

## 🔧 Advanced Features

### Weather Integration (Optional)
1. Get a free API key from [OpenWeatherMap](https://openweathermap.org/api)
2. Set `weather_api_key` in the config
3. Enable `show_weather: True`

### Custom Figlet Fonts
```bash
# Install additional figlet fonts
sudo apt install figlet-fonts

# List available fonts
figlet -l

# Add your favorites to banner_fonts list in config
```

### Performance Tuning
```bash
# For faster startup, disable slow features:
# - Set show_weather: False
# - Set show_ssl_certs: False for systems without SSL services
# - Adjust timeouts in the code if needed
```

## 📋 Troubleshooting

### Common Issues

#### Import Errors
```bash
# Make sure virtual environment is activated
source /opt/motd.dynamic/motd-env/bin/activate
pip install -r requirements.txt
```

#### Permission Errors
```bash
# Fix ownership
sudo chown -R $USER:$USER /opt/motd.dynamic

# Fix permissions
chmod +x motd.dynamic
```

#### Docker Permission Denied
```bash
# Add user to docker group
sudo usermod -aG docker $USER
# Logout and login again
```

#### Slow Performance
```bash
# Disable network-dependent features
# Edit motd.dynamic and set:
# show_weather: False
# Or increase timeout values
```

## 🆚 Comparison with Original

| Feature | Original | Modern Version |
|---------|----------|----------------|
| **Visual Design** | Basic text tables | Rich UI with colors, icons, panels |
| **Performance** | Sequential execution | Threaded/async operations |
| **Error Handling** | Basic try/catch | Graceful degradation |
| **Dependencies** | Old libraries (texttable, uptime) | Modern libraries (rich, requests) |
| **Features** | Basic system info | Docker, SSL, SystemD, quotes |
| **Python Support** | Python 2/3 compatibility | Python 3 native |
| **Configuration** | Global variables | Structured config class |
| **Maintainability** | Monolithic script | Modular OOP design |

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

GNU General Public License v2 or later

## 🙏 Acknowledgments

- Original MOTD script by Mazdak Farrokhzad, Nick Charlton, Dustin Kirkland, and Michael Vogt
- [Rich library](https://github.com/Textualize/rich) for beautiful terminal output
- [PyFiglet](https://github.com/pwaller/pyfiglet) for ASCII art generation
- [PSUtil](https://github.com/giampaolo/psutil) for system information

---

**Made with ❤️ for the Linux community**
