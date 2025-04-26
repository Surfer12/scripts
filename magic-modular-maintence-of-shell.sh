#!/usr/bin/env zsh

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
    
    # Optional: Additional magic shell command (commented out due to potential issues)
    # run_magic_command "shell" "Magic Shell Launch"
    
    log "INFO" "Magic Maintenance Workflow Completed Successfully"
    echo "--- All commands completed ---"
}

# Script Entry Point
main_workflow