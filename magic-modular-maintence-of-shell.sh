#!/usr/bin/env bash

# Magic Shell Maintenance Script
# ---------------------------------------
# Purpose: Comprehensive shell environment maintenance and optimization for macOS
# Version: 2.0
# Author: Goose Shell Automation
# Last Updated: 2025-04-26
#
# Overview:
# This script automates system maintenance tasks with magic commands and comprehensive logging.
# It handles updates, upgrades, cleanup, and self-maintenance with detailed error reporting.

# Configuration File Location
CONFIG_FILE="${HOME}/.config/magic-shell-maintenance.conf"

# Check if npm is installed
check_npm() {
    if command -v npm >/dev/null 2>&1; then
        return 0
    else
        log "WARN" "npm is not installed. Skipping npm update."
        return 1
    fi
}

# NPM Update Function
run_npm_update() {
    if check_npm; then
        log "INFO" "Running npm update"
        echo "Running npm update..."
        
        npm update -g 2>&1 | tee -a "${LOG_FILE}"
        local exit_code=${PIPESTATUS[0]}
        
        if [[ ${exit_code} -eq 0 ]]; then
            log "INFO" "✅ npm update completed successfully"
            echo "✅ npm update completed successfully"
        else
            log "ERROR" "❌ npm update failed"
            echo "❌ npm update failed"
            handle_error "npm update" "npm update failed with exit code ${exit_code}"
        fi
        
        echo
    fi
}

# Python Environment Management Function
run_python_maintenance() {
    if command -v pip3 >/dev/null 2>&1; then
        log "INFO" "Running Python environment maintenance"
        echo "Running Python environment maintenance..."
        
        # Update pip itself
        python3 -m pip install --upgrade pip 2>&1 | tee -a "${LOG_FILE}"
        local pip_exit_code=$?
        
        if [[ ${pip_exit_code} -eq 0 ]]; then
            log "INFO" "✅ pip upgrade completed successfully"
        else
            log "WARN" "⚠️ pip upgrade encountered issues"
        fi
        
        # List outdated packages
        log "INFO" "Checking for outdated packages..."
        python3 -m pip list --outdated 2>&1 | tee -a "${LOG_FILE}"
        
        # Update user packages (optional, can be configured)
        if [[ "${PERFORM_PYTHON_USER_UPDATE}" == "true" ]]; then
            log "INFO" "Updating user packages..."
            python3 -m pip list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 python3 -m pip install -U 2>&1 | tee -a "${LOG_FILE}"
            local update_exit_code=$?
            
            if [[ ${update_exit_code} -eq 0 ]]; then
                log "INFO" "✅ Python packages updated successfully"
            else
                log "WARN" "⚠️ Some package updates may have failed"
            fi
        fi
    else
        log "WARN" "pip3 not found. Skipping Python maintenance."
    fi
    echo
}

# Git Repository Maintenance Function
run_git_maintenance() {
    if command -v git >/dev/null 2>&1; then
        log "INFO" "Running Git maintenance"
        echo "Running Git maintenance..."
        
        # Prune and cleanup
        log "INFO" "Running git garbage collection..."
        git gc --auto 2>&1 | tee -a "${LOG_FILE}"
        
        log "INFO" "Pruning unreachable objects..."
        git prune 2>&1 | tee -a "${LOG_FILE}"
        
        # Optional: clean untracked files (controlled by config)
        if [[ "${PERFORM_GIT_CLEAN}" == "true" ]]; then
            log "INFO" "Cleaning untracked files..."
            # First show what would be deleted
            log "INFO" "Files that would be removed:"
            git clean -fd --dry-run 2>&1 | tee -a "${LOG_FILE}"
            
            # Then actually delete if configured
            git clean -fd 2>&1 | tee -a "${LOG_FILE}"
            local clean_exit_code=$?
            
            if [[ ${clean_exit_code} -eq 0 ]]; then
                log "INFO" "✅ Git clean completed successfully"
            else
                log "WARN" "⚠️ Git clean encountered issues"
            fi
        fi
    else
        log "WARN" "git not found. Skipping Git maintenance."
    fi
    echo
}

# Shell Config Backup Function
run_shell_config_backup() {
    if [[ "${BACKUP_SHELL_CONFIG}" == "true" ]]; then
        local backup_dir="${CONFIG_BACKUP_DIR}/$(date +%Y-%m-%d)"
        log "INFO" "Backing up shell configurations to ${backup_dir}"
        echo "Backing up shell configurations..."
        
        mkdir -p "${backup_dir}"
        
        # Backup common shell config files
        local backup_files=(
            ~/.zshrc
            ~/.bashrc
            ~/.profile
            ~/.zprofile
            ~/.bash_profile
            ~/.zsh_history
            ~/.bash_history
            ~/.zshenv
            ~/.zlogin
            ~/.zlogout
            ~/.inputrc
        )
        
        for file in "${backup_files[@]}"; do
            if [[ -f "${file}" ]]; then
                cp "${file}" "${backup_dir}/" 2>&1 | tee -a "${LOG_FILE}"
                log "INFO" "✅ Backed up ${file}"
            fi
        done
        
        # Backup custom config directories if they exist
        local config_dirs=(
            ~/.config/zsh
            ~/.oh-my-zsh
            ~/.config/bash
        )
        
        for dir in "${config_dirs[@]}"; do
            if [[ -d "${dir}" ]]; then
                cp -R "${dir}" "${backup_dir}/" 2>&1 | tee -a "${LOG_FILE}"
                log "INFO" "✅ Backed up ${dir}"
            fi
        done
        
        # Cleanup old backups
        log "INFO" "Cleaning up old backups..."
        find "${CONFIG_BACKUP_DIR}" -type d -mtime +${MAX_CONFIG_BACKUPS} -exec rm -rf {} + 2>/dev/null
    fi
    echo
}

# System Health Check Function
run_system_health_check() {
    if [[ "${PERFORM_HEALTH_CHECK}" == "true" ]]; then
        log "INFO" "Running system health check"
        echo "Running system health check..."
        
        # Check disk space
        log "INFO" "Checking disk space..."
        df -h / 2>&1 | tee -a "${LOG_FILE}"
        
        # Check memory usage
        log "INFO" "Checking memory usage..."
        vm_stat 2>&1 | tee -a "${LOG_FILE}"
        
        # Check system load
        log "INFO" "Checking system load..."
        sysctl vm.loadavg 2>&1 | tee -a "${LOG_FILE}"
        
        # Check CPU usage
        log "INFO" "Checking CPU usage..."
        top -l 1 -n 0 2>&1 | tee -a "${LOG_FILE}"
        
        # Check for system updates
        log "INFO" "Checking for system updates..."
        softwareupdate -l 2>&1 | tee -a "${LOG_FILE}"
        
        # Check disk health
        log "INFO" "Checking disk health..."
        diskutil verifyVolume / 2>&1 | tee -a "${LOG_FILE}"
    fi
    echo
}

# Network Configuration Check Function
run_network_check() {
    if [[ "${PERFORM_NETWORK_CHECK}" == "true" ]]; then
        log "INFO" "Running network configuration check"
        echo "Running network check..."
        
        # Check DNS configuration
        log "INFO" "Checking DNS configuration..."
        scutil --dns 2>&1 | tee -a "${LOG_FILE}"
        
        # Check network interfaces
        log "INFO" "Checking network interfaces..."
        ifconfig 2>&1 | tee -a "${LOG_FILE}"
        
        # Check active network services
        log "INFO" "Checking network services..."
        networksetup -listallnetworkservices 2>&1 | tee -a "${LOG_FILE}"
        
        # Basic connectivity test
        log "INFO" "Testing network connectivity..."
        ping -c 3 8.8.8.8 2>&1 | tee -a "${LOG_FILE}"
        
        # Check current network location
        log "INFO" "Checking network location..."
        networksetup -getcurrentlocation 2>&1 | tee -a "${LOG_FILE}"
        
        # Check Wi-Fi status if available
        if networksetup -listallhardwareports | grep -q "Wi-Fi"; then
            log "INFO" "Checking Wi-Fi status..."
            networksetup -getairportnetwork en0 2>&1 | tee -a "${LOG_FILE}"
        fi
    fi
    echo
}

# Homebrew Security Integration
run_homebrew_security() {
    if command -v brew >/dev/null 2>&1; then
        if [[ "${PERFORM_HOMEBREW_SECURITY}" == "true" ]]; then
            log "INFO" "Running Homebrew security checks"
            echo "Running Homebrew security checks..."
            
            # Check Homebrew installation
            log "INFO" "Checking Homebrew installation..."
            brew doctor 2>&1 | tee -a "${LOG_FILE}"
            
            # Check for vulnerable formulae
            log "INFO" "Checking for vulnerable formulae..."
            brew audit --strict 2>&1 | tee -a "${LOG_FILE}"
            
            # Update Homebrew security components
            if [[ "${HOMEBREW_SECURITY_UPDATE}" == "true" ]]; then
                log "INFO" "Updating Homebrew security components..."
                brew upgrade openssl gnupg 2>&1 | tee -a "${LOG_FILE}"
            fi
        fi
    else
        log "WARN" "Homebrew not found. Skipping security checks."
    fi
    echo
}

# Fallback Configuration
DEFAULT_CONFIG() {
    # Default Logging Configuration
    LOG_BASE_DIR="${HOME}/.logs"
    LOG_DIR="${LOG_BASE_DIR}/shell_maintenance"
    LOG_FILE="${LOG_DIR}/maintenance_$(date +%Y-%m-%d).log"
    LOG_LEVEL="info"
    MAX_LOG_AGE_DAYS=45

    # Maintenance Workflow Defaults
    PERFORM_UPDATE=true
    PERFORM_UPGRADE=true
    PERFORM_SELF_UPDATE=true
    PERFORM_CLEANUP=true
    PERFORM_NPM_UPDATE=true
    
    # Python Configuration
    PERFORM_PYTHON_MAINTENANCE=true
    PERFORM_PYTHON_USER_UPDATE=false
    
    # Git Configuration
    PERFORM_GIT_MAINTENANCE=true
    PERFORM_GIT_CLEAN=false
    
    # Shell Configuration Backup
    BACKUP_SHELL_CONFIG=true
    CONFIG_BACKUP_DIR="${HOME}/.shell_config_backups"
    MAX_CONFIG_BACKUPS=5
    
    # System Health Check
    PERFORM_HEALTH_CHECK=true
    DISK_SPACE_THRESHOLD=90  # Alert if disk usage > 90%
    MEMORY_THRESHOLD=90      # Alert if memory usage > 90%
    
    # Network Configuration
    PERFORM_NETWORK_CHECK=true
    PING_TEST_HOST="8.8.8.8"
    PING_TIMEOUT=5
    
    # Homebrew Security
    PERFORM_HOMEBREW_SECURITY=true
    HOMEBREW_SECURITY_UPDATE=true

    # Timeout and Security Defaults
    COMMAND_TIMEOUT=900  # 15 minutes for maintenance tasks
    SEND_NOTIFICATIONS=true
    NOTIFICATION_METHOD="email"
    NOTIFICATION_RECIPIENT="ryandavidoates@gmail.com"
}

# Ensure Log Directory Exists
ensure_log_directory() {
    # Create base log directory if it doesn't exist
    if [[ -n "${LOG_BASE_DIR}" ]] && [[ ! -d "${LOG_BASE_DIR}" ]]; then
        mkdir -p "${LOG_BASE_DIR}" 2>/dev/null || true
    fi

    # Create specific log directory if it doesn't exist
    if [[ -n "${LOG_DIR}" ]] && [[ ! -d "${LOG_DIR}" ]]; then
        mkdir -p "${LOG_DIR}" 2>/dev/null || true
    fi
}

# Logging Function
log() {
    local level="${1}"
    local message="${2}"
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local color=""
    local reset="\033[0m"

    # Ensure log directory exists before logging
    ensure_log_directory

    # Color-code log levels
    case "${level}" in
        DEBUG)
            color="\033[36m"  # Cyan
            ;;
        INFO)
            color="\033[32m"  # Green
            ;;
        WARN)
            color="\033[33m"  # Yellow
            ;;
        ERROR)
            color="\033[31m"  # Red
            ;;
    esac

    # Always output to terminal
    echo -e "${color}[${timestamp}] [${level}] ${message}${reset}"

    # Log to file based on LOG_LEVEL
    case "${LOG_LEVEL}" in
        debug)
            echo -e "${color}[${timestamp}] [${level}] ${message}${reset}" >> "${LOG_FILE}"
            ;;
        info)
            if [[ "${level}" != "DEBUG" ]]; then
                echo -e "${color}[${timestamp}] [${level}] ${message}${reset}" >> "${LOG_FILE}"
            fi
            ;;
        warn)
            if [[ "${level}" == "WARN" || "${level}" == "ERROR" ]]; then
                echo -e "${color}[${timestamp}] [${level}] ${message}${reset}" >> "${LOG_FILE}"
            fi
            ;;
        error)
            if [[ "${level}" == "ERROR" ]]; then
                echo -e "${color}[${timestamp}] [${level}] ${message}${reset}" >> "${LOG_FILE}"
            fi
            ;;
    esac
}

# Error Handling Function
handle_error() {
    local command="${1}"
    local error_message="${2}"
    
    log "ERROR" "Command failed: ${command}"
    log "ERROR" "Error details: ${error_message}"
    
    # Optional: Send notification
    if [[ "${SEND_NOTIFICATIONS}" == "true" ]]; then
        echo "${error_message}" | mail -s "Magic Maintenance Failure" "${NOTIFICATION_RECIPIENT}"
    fi
    
    exit 1
}

# Load Configuration
load_configuration() {
    # Initialize default configuration
    DEFAULT_CONFIG

    # Check if configuration file exists
    if [[ -f "${CONFIG_FILE}" ]]; then
        # Source the configuration file
        # shellcheck source=/dev/null
        source "${CONFIG_FILE}"
        log "INFO" "Configuration loaded from ${CONFIG_FILE}"
    else
        log "WARN" "No configuration file found at ${CONFIG_FILE}. Using default settings."
    fi

    # Ensure log directory exists after configuration load
    ensure_log_directory
}

# Run Magic Command Wrapper
run_magic_command() {
    local command="${1}"
    local description="${2}"
    
    log "INFO" "--- Running '${command}' ---"
    echo "--- Running '${command}' ---"
    
    # Execute the magic command
    magic "${command}"
    local exit_code=$?
    
    # Check command status
    if [[ ${exit_code} -eq 0 ]]; then
        log "INFO" "✅ '${command}' succeeded."
        echo "✅ '${command}' succeeded."
    else
        log "ERROR" "❌ '${command}' failed."
        echo "❌ '${command}' failed. Exiting."
        handle_error "${command}" "Magic command failed with exit code ${exit_code}"
    fi
    
    # Add a blank line for separation
    echo
}

# Main Workflow
main_workflow() {
    log "INFO" "Starting Magic Maintenance Workflow"
    
    # Load configuration
    load_configuration
    
    # Perform maintenance tasks if configured
    if [[ "${PERFORM_UPDATE}" == "true" ]]; then
        run_magic_command "update" "System Update"
    fi
    
    if [[ "${PERFORM_UPGRADE}" == "true" ]]; then
        run_magic_command "upgrade" "System Upgrade"
    fi
    
    if [[ "${PERFORM_SELF_UPDATE}" == "true" ]]; then
        run_magic_command "self-update" "Magic Self-Update"
    fi
    
    if [[ "${PERFORM_CLEANUP}" == "true" ]]; then
        run_magic_command "clean" "System Cleanup"
    fi
    
    # Run System Health Check early to catch any issues
    if [[ "${PERFORM_HEALTH_CHECK}" == "true" ]]; then
        run_system_health_check
    fi
    
    # Run Network Check
    if [[ "${PERFORM_NETWORK_CHECK}" == "true" ]]; then
        run_network_check
    fi
    
    # Homebrew Security Check
    if [[ "${PERFORM_HOMEBREW_SECURITY}" == "true" ]]; then
        run_homebrew_security
    fi
    
    # Package Management Updates
    if [[ "${PERFORM_NPM_UPDATE}" == "true" ]]; then
        run_npm_update
    fi
    
    if [[ "${PERFORM_PYTHON_MAINTENANCE}" == "true" ]]; then
        run_python_maintenance
    fi
    
    # Git Maintenance
    if [[ "${PERFORM_GIT_MAINTENANCE}" == "true" ]]; then
        run_git_maintenance
    fi
    
    # Shell Config Backup (do this last after all updates)
    if [[ "${BACKUP_SHELL_CONFIG}" == "true" ]]; then
        run_shell_config_backup
    fi
    
    log "INFO" "Magic Maintenance Workflow Completed Successfully"
    echo "--- All commands completed ---"
}

# Script Entry Point
main_workflow