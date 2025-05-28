#!/usr/bin/env zsh
# macOS Setup Script for Scripts Collection
# Compatible with Zsh and Bash on macOS

# Detect shell and set appropriate commands
if [[ -n "$ZSH_VERSION" ]]; then
    CURRENT_SHELL="zsh"
elif [[ -n "$BASH_VERSION" ]]; then
    CURRENT_SHELL="bash"
else
    echo "Unsupported shell. Please use Zsh or Bash."
    exit 1
fi

# Text formatting (compatible with both Zsh and Bash)
BOLD=$(tput bold)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RED=$(tput setaf 1)
BLUE=$(tput setaf 4)
NC=$(tput sgr0) # No Color

# macOS-specific configuration file
CONFIG_FILE="$HOME/.macos_scripts_config"
SCRIPTS_DIR="$( cd "$( dirname "${(%):-%x}" )" && pwd )"  # Zsh-compatible dirname

# Default configuration values (macOS-specific)
DEFAULT_WIRESHARK_CAPTURE_DIR="$HOME/Documents/Wireshark_Captures"
DEFAULT_CAPTURE_DURATION=30
DEFAULT_MAGIC_TOOL_PATH="/usr/local/bin/magic"
DEFAULT_HOMEBREW_CLEANUP=true
DEFAULT_HOMEBREW_AUTO_UPDATE=true
DEFAULT_HOMEBREW_UPGRADE_ALL=true

# Function to print section headers
print_header() {
    printf "\n${BOLD}${BLUE}%s${NC}\n" "$1"
}

# Function to print success messages
print_success() {
    printf "${GREEN}✓ %s${NC}\n" "$1"
}

# Function to print warning messages
print_warning() {
    printf "${YELLOW}! %s${NC}\n" "$1"
}

# Function to print error messages
print_error() {
    printf "${RED}✗ %s${NC}\n" "$1"
}

# macOS-compatible command existence check
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to create or update configuration
create_config() {
    print_header "Creating macOS Configuration File"
    
    # Check if config file exists
    if [[ -f "$CONFIG_FILE" ]]; then
        print_warning "Configuration file already exists. Loading existing values..."
        source "$CONFIG_FILE"
    fi
    
    # Prompt for configuration (macOS-style)
    echo -e "${BOLD}Please configure your macOS script settings:${NC}"
    
    # Use read with -p for macOS compatibility
    read -p "Wireshark capture directory [${WIRESHARK_CAPTURE_DIR:-$DEFAULT_WIRESHARK_CAPTURE_DIR}]: " input
    WIRESHARK_CAPTURE_DIR=${input:-${WIRESHARK_CAPTURE_DIR:-$DEFAULT_WIRESHARK_CAPTURE_DIR}}
    
    read -p "Default capture duration in seconds [${CAPTURE_DURATION:-$DEFAULT_CAPTURE_DURATION}]: " input
    CAPTURE_DURATION=${input:-${CAPTURE_DURATION:-$DEFAULT_CAPTURE_DURATION}}
    
    read -p "Path to magic tool [${MAGIC_TOOL_PATH:-$DEFAULT_MAGIC_TOOL_PATH}]: " input
    MAGIC_TOOL_PATH=${input:-${MAGIC_TOOL_PATH:-$DEFAULT_MAGIC_TOOL_PATH}}
    
    read -p "Enable Homebrew cleanup (true/false) [${HOMEBREW_CLEANUP:-$DEFAULT_HOMEBREW_CLEANUP}]: " input
    HOMEBREW_CLEANUP=${input:-${HOMEBREW_CLEANUP:-$DEFAULT_HOMEBREW_CLEANUP}}
    
    read -p "Enable Homebrew auto-update (true/false) [${HOMEBREW_AUTO_UPDATE:-$DEFAULT_HOMEBREW_AUTO_UPDATE}]: " input
    HOMEBREW_AUTO_UPDATE=${input:-${HOMEBREW_AUTO_UPDATE:-$DEFAULT_HOMEBREW_AUTO_UPDATE}}
    
    read -p "Enable automatic upgrade of all Homebrew packages (true/false) [${HOMEBREW_UPGRADE_ALL:-$DEFAULT_HOMEBREW_UPGRADE_ALL}]: " input
    HOMEBREW_UPGRADE_ALL=${input:-${HOMEBREW_UPGRADE_ALL:-$DEFAULT_HOMEBREW_UPGRADE_ALL}}
    
    # Write configuration to file (macOS-specific)
    cat > "$CONFIG_FILE" << EOF
# macOS Scripts Collection Configuration
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

# macOS Homebrew installation
install_homebrew() {
    print_header "Checking for Homebrew on macOS"
    
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
    if [[ -f "$SCRIPTS_DIR/Brewfile" ]]; then
        print_warning "Installing packages from Brewfile..."
        brew bundle --file="$SCRIPTS_DIR/Brewfile"
        print_success "Packages installed from Brewfile"
    else
        print_warning "No Brewfile found. Skipping package installation."
    fi
}

# macOS Wireshark installation
install_wireshark() {
    print_header "Installing Wireshark on macOS"
    
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

# Check for magic tool (macOS version)
check_magic_tool() {
    print_header "Checking for magic tool on macOS"
    
    if [[ -f "$MAGIC_TOOL_PATH" ]] || command_exists magic; then
        print_success "Magic tool found"
    else
        print_warning "Magic tool not found at $MAGIC_TOOL_PATH"
        print_warning "Some scripts may not function correctly without the magic tool"
        print_warning "Please install the magic tool manually or update the path in the configuration"
    fi
}

# Update scripts with configuration (macOS-specific)
update_scripts() {
    print_header "Updating scripts with macOS configuration"
    
    # Use gsed if available (brew install gnu-sed)
    local SED_CMD
    if command_exists gsed; then
        SED_CMD="gsed"
    else
        SED_CMD="sed"
    fi
    
    # Update wireshark__speedtest.sh
    if [[ -f "$SCRIPTS_DIR/wireshark__speedtest.sh" ]]; then
        "$SED_CMD" -i.bak "s|OUTPUT_DIR=\"\$HOME/wireshark_speedtests\"|OUTPUT_DIR=\"$WIRESHARK_CAPTURE_DIR\"|g" "$SCRIPTS_DIR/wireshark__speedtest.sh"
        "$SED_CMD" -i.bak "s|DURATION=30|DURATION=$CAPTURE_DURATION|g" "$SCRIPTS_DIR/wireshark__speedtest.sh"
        rm -f "$SCRIPTS_DIR/wireshark__speedtest.sh.bak"
        print_success "Updated wireshark__speedtest.sh with new configuration"
    fi
}

# Make scripts executable (macOS version)
make_executable() {
    print_header "Making scripts executable"
    
    find "$SCRIPTS_DIR" -type f -name "*.sh" -exec chmod +x {} \;
    print_success "All scripts are now executable"
}

# Main function
main() {
    print_header "macOS Scripts Collection Setup"
    echo "This script will install dependencies and configure your macOS scripts collection."
    
    # Strict macOS check
    if [[ "$(uname -s)" != "Darwin" ]]; then
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
    echo "Your macOS scripts collection is now ready to use."
    echo "Configuration file: $CONFIG_FILE"
    echo "You can re-run this setup script at any time to update your configuration."
}

# Run the main function
main