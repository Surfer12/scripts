#!/bin/bash
#
# Setup Script for Scripts Collection
# This script installs dependencies and configures settings for all scripts in the collection.
#

# Text formatting
BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

# Configuration file
CONFIG_FILE="$HOME/.scripts_config"
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default configuration values
DEFAULT_WIRESHARK_CAPTURE_DIR="$HOME/wireshark_speedtests"
DEFAULT_CAPTURE_DURATION=30
DEFAULT_MAGIC_TOOL_PATH="/usr/local/bin/magic"
DEFAULT_HOMEBREW_CLEANUP=true
DEFAULT_HOMEBREW_AUTO_UPDATE=true
DEFAULT_HOMEBREW_UPGRADE_ALL=true

# Function to print section headers
print_header() {
    echo -e "\n${BOLD}${BLUE}$1${NC}\n"
}

# Function to print success messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print warning messages
print_warning() {
    echo -e "${YELLOW}! $1${NC}"
}

# Function to print error messages
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to create or update configuration
create_config() {
    print_header "Creating configuration file"
    
    # Check if config file exists
    if [ -f "$CONFIG_FILE" ]; then
        print_warning "Configuration file already exists. Loading existing values..."
        source "$CONFIG_FILE"
    fi
    
    # Ask for configuration values or use defaults/existing
    echo -e "${BOLD}Please configure your settings:${NC}"
    
    # Wireshark capture directory
    read -p "Wireshark capture directory [${WIRESHARK_CAPTURE_DIR:-$DEFAULT_WIRESHARK_CAPTURE_DIR}]: " input
    WIRESHARK_CAPTURE_DIR=${input:-${WIRESHARK_CAPTURE_DIR:-$DEFAULT_WIRESHARK_CAPTURE_DIR}}
    
    # Capture duration
    read -p "Default capture duration in seconds [${CAPTURE_DURATION:-$DEFAULT_CAPTURE_DURATION}]: " input
    CAPTURE_DURATION=${input:-${CAPTURE_DURATION:-$DEFAULT_CAPTURE_DURATION}}
    
    # Magic tool path
    read -p "Path to magic tool [${MAGIC_TOOL_PATH:-$DEFAULT_MAGIC_TOOL_PATH}]: " input
    MAGIC_TOOL_PATH=${input:-${MAGIC_TOOL_PATH:-$DEFAULT_MAGIC_TOOL_PATH}}
    
    # Homebrew cleanup
    read -p "Enable Homebrew cleanup (true/false) [${HOMEBREW_CLEANUP:-$DEFAULT_HOMEBREW_CLEANUP}]: " input
    HOMEBREW_CLEANUP=${input:-${HOMEBREW_CLEANUP:-$DEFAULT_HOMEBREW_CLEANUP}}
    
    # Homebrew auto-update
    read -p "Enable Homebrew auto-update (true/false) [${HOMEBREW_AUTO_UPDATE:-$DEFAULT_HOMEBREW_AUTO_UPDATE}]: " input
    HOMEBREW_AUTO_UPDATE=${input:-${HOMEBREW_AUTO_UPDATE:-$DEFAULT_HOMEBREW_AUTO_UPDATE}}
    
    # Homebrew upgrade all
    read -p "Enable automatic upgrade of all Homebrew packages (true/false) [${HOMEBREW_UPGRADE_ALL:-$DEFAULT_HOMEBREW_UPGRADE_ALL}]: " input
    HOMEBREW_UPGRADE_ALL=${input:-${HOMEBREW_UPGRADE_ALL:-$DEFAULT_HOMEBREW_UPGRADE_ALL}}
    
    # Write configuration to file
    cat > "$CONFIG_FILE" << EOF
# Scripts Collection Configuration
# Generated on $(date)

# Wireshark settings
WIRESHARK_CAPTURE_DIR="$WIRESHARK_CAPTURE_DIR"
CAPTURE_DURATION=$CAPTURE_DURATION

# Magic tool settings
MAGIC_TOOL_PATH="$MAGIC_TOOL_PATH"

# Homebrew settings
HOMEBREW_CLEANUP=$HOMEBREW_CLEANUP
HOMEBREW_AUTO_UPDATE=$HOMEBREW_AUTO_UPDATE
HOMEBREW_UPGRADE_ALL=$HOMEBREW_UPGRADE_ALL
EOF
    
    print_success "Configuration saved to $CONFIG_FILE"
}

# Function to check and install Homebrew
install_homebrew() {
    print_header "Checking for Homebrew"
    
    if command_exists brew; then
        print_success "Homebrew is already installed"
    else
        print_warning "Homebrew not found. Installing..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        if command_exists brew; then
            print_success "Homebrew installed successfully"
        else
            print_error "Failed to install Homebrew"
            exit 1
        fi
    fi
    
    # Update Homebrew
    print_warning "Updating Homebrew..."
    brew update
    print_success "Homebrew updated"
    
    # Install from Brewfile if it exists
    if [ -f "$SCRIPTS_DIR/Brewfile" ]; then
        print_warning "Installing packages from Brewfile..."
        brew bundle --file="$SCRIPTS_DIR/Brewfile"
        print_success "Packages installed from Brewfile"
    else
        print_warning "No Brewfile found. Skipping package installation."
    fi
}

# Function to install Wireshark and dependencies
install_wireshark() {
    print_header "Installing Wireshark and dependencies"
    
    if command_exists tshark; then
        print_success "Wireshark is already installed"
    else
        print_warning "Wireshark not found. Installing..."
        brew install --cask wireshark
        
        if command_exists tshark; then
            print_success "Wireshark installed successfully"
        else
            print_error "Failed to install Wireshark"
            exit 1
        fi
    fi
    
    # Create capture directory
    mkdir -p "$WIRESHARK_CAPTURE_DIR"
    print_success "Created capture directory: $WIRESHARK_CAPTURE_DIR"
}

# Function to check for magic tool
check_magic_tool() {
    print_header "Checking for magic tool"
    
    if [ -f "$MAGIC_TOOL_PATH" ] || command_exists magic; then
        print_success "Magic tool found"
    else
        print_warning "Magic tool not found at $MAGIC_TOOL_PATH"
        print_warning "Some scripts may not function correctly without the magic tool"
        print_warning "Please install the magic tool manually or update the path in the configuration"
    fi
}

# Function to update scripts with configuration
update_scripts() {
    print_header "Updating scripts with configuration"
    
    # Update wireshark__speedtest.sh
    if [ -f "$SCRIPTS_DIR/wireshark__speedtest.sh" ]; then
        sed -i.bak "s|OUTPUT_DIR=\"\$HOME/wireshark_speedtests\"|OUTPUT_DIR=\"$WIRESHARK_CAPTURE_DIR\"|g" "$SCRIPTS_DIR/wireshark__speedtest.sh"
        sed -i.bak "s|DURATION=30|DURATION=$CAPTURE_DURATION|g" "$SCRIPTS_DIR/wireshark__speedtest.sh"
        rm -f "$SCRIPTS_DIR/wireshark__speedtest.sh.bak"
        print_success "Updated wireshark__speedtest.sh with new configuration"
    fi
    
    # Update magic-modular-maintence-of-shell.sh if needed
    if [ -f "$SCRIPTS_DIR/magic-modular-maintence-of-shell.sh" ]; then
        if ! command_exists magic && [ -f "$MAGIC_TOOL_PATH" ]; then
            sed -i.bak "s|magic |$MAGIC_TOOL_PATH |g" "$SCRIPTS_DIR/magic-modular-maintence-of-shell.sh"
            rm -f "$SCRIPTS_DIR/magic-modular-maintence-of-shell.sh.bak"
            print_success "Updated magic-modular-maintence-of-shell.sh with correct path"
        fi
    fi
    
    # Update homebrew_security.sh if needed
    if [ -f "$SCRIPTS_DIR/homebrew_security.sh" ]; then
        if [ "$HOMEBREW_CLEANUP" = "false" ]; then
            sed -i.bak '/brew cleanup/s/^/#/' "$SCRIPTS_DIR/homebrew_security.sh"
            rm -f "$SCRIPTS_DIR/homebrew_security.sh.bak"
            print_success "Disabled Homebrew cleanup in homebrew_security.sh"
        fi
    fi
}

# Function to make scripts executable
make_executable() {
    print_header "Making scripts executable"
    
    find "$SCRIPTS_DIR" -name "*.sh" -type f -exec chmod +x {} \;
    print_success "All scripts are now executable"
}

# Main function
main() {
    print_header "Scripts Collection Setup"
    echo "This script will install dependencies and configure your scripts collection."
    
    # Check if running on macOS
    if [ "$(uname)" != "Darwin" ]; then
        print_error "This setup script is designed for macOS only."
        exit 1
    fi
    
    # Create or update configuration
    create_config
    
    # Source the configuration
    source "$CONFIG_FILE"
    
    # Install dependencies
    install_homebrew
    install_wireshark
    check_magic_tool
    
    # Update scripts with configuration
    update_scripts
    
    # Make scripts executable
    make_executable
    
    print_header "Setup Complete!"
    echo "Your scripts collection is now ready to use."
    echo "Configuration file: $CONFIG_FILE"
    echo "You can re-run this setup script at any time to update your configuration."
}

# Run the main function
main
