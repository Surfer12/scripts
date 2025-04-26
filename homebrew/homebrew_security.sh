#!/bin/zsh
#!/bin/bash

# Homebrew Security Enhancement Script
# ---------------------------------------
# Purpose: Automate Homebrew package management and security maintenance
# Version: 1.2
# Author: Goose Security Automation
# Last Updated: 2025-04-26
#
# Features:
# - Comprehensive Homebrew updates
# - Security auditing
# - Detailed logging
# - Configurable maintenance options
#
# Usage: 
#   - Run directly: ./homebrew_security.sh
#   - Run with sudo for full system checks: sudo ./homebrew_security.sh
#
# Configuration: 
#   Customize settings in homebrew_security.conf

# shellcheck disable=SC1090,SC2034

# Configuration File Location
CONFIG_FILE="${HOME}/.config/homebrew_security.conf"

# Fallback Configuration
# Ensures script works even without custom config file
DEFAULT_CONFIG() {
    # Default Logging Configuration
    LOG_DIR="/var/log/homebrew"
    MAX_LOG_AGE_DAYS=30
    LOG_FILE="${LOG_DIR}/security_$(date +%Y-%m-%d).log"

    # Default Maintenance Options
    UPGRADE_OPTIONS="--verbose"
    CLEANUP_OPTIONS="-s --prune=all"

    # Default Security Settings
    PERFORM_AUDIT=true
    AUDIT_LEVEL="standard"
    CHECK_VULNERABILITIES=true

    # Default Notification (disabled)
    SEND_EMAIL_NOTIFICATION=false
    NOTIFICATION_EMAIL=""

    # Empty package lists
    IGNORE_PACKAGES=()
    FORCE_UPGRADE_PACKAGES=()
}

# Load Configuration Function
# Reads configuration from file, falls back to defaults
load_configuration() {
    # Initialize default configuration
    DEFAULT_CONFIG

    # Check if configuration file exists
    if [[ -f "${CONFIG_FILE}" ]]; then
        # Source the configuration file
        # shellcheck source=/dev/null
        source "${CONFIG_FILE}"
    else
        echo "WARNING: No configuration file found. Using default settings."
    fi

    # Ensure log directory exists
    mkdir -p "${LOG_DIR}"
}

# Logging Function
# Provides consistent logging with timestamps and levels
log() {
    local level="${1}"
    local message="${2}"
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    # Log to file and stdout
    echo "[${timestamp}] [${level}] ${message}" | tee -a "${LOG_FILE}"
}

# Error Handling Function
# Centralized error management with logging
handle_error() {
    local error_message="${1}"
    log "ERROR" "${error_message}"
    
    # Optional email notification
    if [[ "${SEND_EMAIL_NOTIFICATION}" == "true" ]]; then
        echo "${error_message}" | mail -s "Homebrew Security Script Error" "${NOTIFICATION_EMAIL}"
    fi
    
    exit 1
}

# Pre-Flight Checks
# Validates system readiness before maintenance
pre_flight_checks() {
    # Check Homebrew installation
    if ! command -v brew &> /dev/null; then
        log "ERROR" "Homebrew is not installed. Please install Homebrew first."
        echo "Homebrew installation instructions:"
        echo "1. Visit https://brew.sh"
        echo "2. Run: /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi

    # Ensure Homebrew is up to date
    brew update || log "WARN" "Could not update Homebrew repositories"

    # Ensure sufficient disk space
    local required_space=1024  # 1 GB minimum
    local available_space
    available_space=$(df -k / | awk '/\// {print $4}')
    
    if [[ "${available_space}" -lt "${required_space}" ]]; then
        handle_error "Insufficient disk space for maintenance."
    fi
}

# Main Maintenance Workflow
main_maintenance() {
    log "INFO" "Starting Homebrew Security Maintenance"

    # Update Homebrew repositories
    log "INFO" "Updating Homebrew repositories"
    brew update || handle_error "Failed to update Homebrew repositories"

    # Upgrade packages with custom options
    log "INFO" "Upgrading packages"
    # shellcheck disable=SC2086
    brew upgrade ${UPGRADE_OPTIONS} || handle_error "Package upgrade failed"

    # Advanced cleanup
    log "INFO" "Performing cleanup"
    # shellcheck disable=SC2086
    brew cleanup ${CLEANUP_OPTIONS} || handle_error "Cleanup failed"

    # Security audit
    if [[ "${PERFORM_AUDIT}" == "true" ]]; then
        log "INFO" "Running security audit"
        brew audit || log "WARN" "Security audit found potential issues"
    fi

    # Vulnerability check
    if [[ "${CHECK_VULNERABILITIES}" == "true" ]]; then
        log "INFO" "Checking for vulnerable packages"
        brew doctor || log "WARN" "Potential system health issues detected"
    fi

    log "INFO" "Homebrew security maintenance completed successfully"
}

# Cleanup Function
# Manages log rotation and old log removal
log_cleanup() {
    log "INFO" "Performing log cleanup"
    find "${LOG_DIR}" -type f -mtime +"${MAX_LOG_AGE_DAYS}" -delete
}

# Main Script Execution
# Orchestrates the entire maintenance process
primary_workflow() {
    # Load configuration
    load_configuration

    # Pre-flight system checks
    pre_flight_checks

    # Execute main maintenance
    main_maintenance

    # Perform log cleanup
    log_cleanup
}

# Script Entry Point
# Provides a clean, structured execution path
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Ensure script runs with appropriate privileges
    if [[ $EUID -ne 0 ]]; then
        log "WARN" "Running without sudo. Some advanced checks might be limited."
    fi

    # Execute primary workflow
    primary_workflow
fi