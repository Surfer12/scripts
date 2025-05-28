#!/usr/bin/env bash
#
# ai_code_updater.sh - Update and manage Claude AI and OpenAI Codex API access
#
# This script automates the process of updating and managing access to Claude AI
# and OpenAI Codex. It handles API key management, version checking, and
# configuration updates for both services.
#
# Usage:
#   ./ai_code_updater.sh [options]
#
# Options:
#   -c, --claude        Update Claude AI only
#   -o, --openai        Update OpenAI Codex only
#   -g, --goose         Update Goose AI only
#   -a, --all           Update all services (default)
#   -k, --keys          Update API keys only
#   -s, --status        Check current status of all services
#       --cleanup       Clean up temporary files and logs
#   -h, --help          Display this help message
#
# Examples:
#   ./ai_code_updater.sh --all    # Update all services
#   ./ai_code_updater.sh -s       # Check status only
#   ./ai_code_updater.sh -c -k    # Update Claude API keys only
#   ./ai_code_updater.sh -g       # Update Goose AI only
#   ./ai_code_updater.sh --cleanup # Clean up temporary files

set -eo pipefail

# Configuration files
CONFIG_DIR="${HOME}/.config/ai_code"
CLAUDE_CONFIG="${CONFIG_DIR}/claude_config.json"
OPENAI_CONFIG="${CONFIG_DIR}/openai_config.json"
GOOSE_CONFIG="${CONFIG_DIR}/goose_config.json"
STATE_LOG="${CONFIG_DIR}/state_log.json"
DOCUMENTATION_FILE="${CONFIG_DIR}/execution_history.md"

# Git configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GIT_ENABLED=true

# Claude API information
CLAUDE_API_URL="https://api.anthropic.com"
CLAUDE_VERSION="2023-06-01"

# OpenAI API information
OPENAI_API_URL="https://api.openai.com"
OPENAI_CODEX_MODEL="gpt-4-turbo" # Updated to latest code-capable model

# Goose AI from Block.io information
GOOSE_API_URL="https://api.goose.ai"
GOOSE_MODEL="gpt-neo-20b" # Default model for Goose

# Text formatting
BOLD="\033[1m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
RESET="\033[0m"

# Display a formatted message
log_message() {
  local level="$1"
  local message="$2"
  local prefix=""
  
  case "$level" in
    "info")     prefix="${BLUE}[INFO]${RESET}"    ;;
    "success")  prefix="${GREEN}[SUCCESS]${RESET}" ;;
    "warning")  prefix="${YELLOW}[WARNING]${RESET}" ;;
    "error")    prefix="${RED}[ERROR]${RESET}"   ;;
    *)          prefix="[LOG]"                  ;;
  esac
  
  echo -e "${prefix} ${message}"
}

# Display error message and exit
fail() {
  log_message "error" "$1"
  exit 1
}

# Initialize git repository if not already present
init_git_support() {
  if [[ "$GIT_ENABLED" == "true" ]] && command -v git >/dev/null 2>&1; then
    if [[ ! -d "$SCRIPT_DIR/.git" ]]; then
      log_message "info" "Initializing git repository for script version control"
      (cd "$SCRIPT_DIR" && git init && git add . && git commit -m "Initial commit of AI code updater script")
    fi
  fi
}

# Commit changes to git if enabled
commit_changes() {
  local message="$1"
  if [[ "$GIT_ENABLED" == "true" ]] && command -v git >/dev/null 2>&1 && [[ -d "$SCRIPT_DIR/.git" ]]; then
    (cd "$SCRIPT_DIR" && git add . && git commit -m "$message" 2>/dev/null || true)
    log_message "info" "Changes committed to git: $message"
  fi
}

# Log execution state to JSON file
log_state() {
  local service="$1"
  local action="$2"
  local status="$3"
  local details="$4"
  
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local entry="{
    \"timestamp\": \"$timestamp\",
    \"service\": \"$service\",
    \"action\": \"$action\",
    \"status\": \"$status\",
    \"details\": \"$details\",
    \"script_version\": \"$(git -C "$SCRIPT_DIR" rev-parse --short HEAD 2>/dev/null || echo 'unknown')\"
  }"
  
  # Initialize state log if it doesn't exist
  if [[ ! -f "$STATE_LOG" ]]; then
    echo "[]" > "$STATE_LOG"
  fi
  
  # Add new entry to state log
  local temp_file=$(mktemp)
  jq --argjson entry "$entry" '. += [$entry]' "$STATE_LOG" > "$temp_file" && mv "$temp_file" "$STATE_LOG"
}

# Update documentation with execution history
update_documentation() {
  local action="$1"
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  
  if [[ ! -f "$DOCUMENTATION_FILE" ]]; then
    cat > "$DOCUMENTATION_FILE" << EOF
# AI Code Updater Execution History

This document tracks the execution history of the AI Code Updater script.

## Recent Executions

EOF
  fi
  
  # Add new entry to documentation
  echo "- **$timestamp**: $action" >> "$DOCUMENTATION_FILE"
  
  # Keep only last 50 entries
  tail -n 52 "$DOCUMENTATION_FILE" > "${DOCUMENTATION_FILE}.tmp" && mv "${DOCUMENTATION_FILE}.tmp" "$DOCUMENTATION_FILE"
}

# Clean up unnecessary files and old logs
cleanup_files() {
  log_message "info" "Cleaning up unnecessary files"
  
  # Remove temporary files
  find "$CONFIG_DIR" -name "*.tmp" -type f -delete 2>/dev/null || true
  find "$CONFIG_DIR" -name "*.bak" -type f -delete 2>/dev/null || true
  
  # Rotate state log if it gets too large (keep last 1000 entries)
  if [[ -f "$STATE_LOG" ]] && [[ $(jq length "$STATE_LOG" 2>/dev/null || echo 0) -gt 1000 ]]; then
    local temp_file=$(mktemp)
    jq '.[length-1000:]' "$STATE_LOG" > "$temp_file" && mv "$temp_file" "$STATE_LOG"
    log_message "info" "Rotated state log to keep last 1000 entries"
  fi
  
  # Clean up old script backups if any
  find "$SCRIPT_DIR" -name "ai_code_updater.sh.bak*" -type f -mtime +7 -delete 2>/dev/null || true
  
  log_state "system" "cleanup" "success" "Cleaned up temporary files and rotated logs"
}

# Create configuration directory if it doesn't exist
ensure_config_dir() {
  if [[ ! -d "${CONFIG_DIR}" ]]; then
    log_message "info" "Creating configuration directory: ${CONFIG_DIR}"
    mkdir -p "${CONFIG_DIR}" || fail "Failed to create configuration directory"
    chmod 700 "${CONFIG_DIR}" # Secure permissions for API keys
  fi
}

# Check if a command exists
check_command() {
  if ! command -v "$1" &> /dev/null; then
    fail "Required command not found: $1. Please install it and try again."
  fi
}

# Retry function for API calls
retry_api_call() {
  local max_attempts=3
  local attempt=1
  local delay=2
  local command="$*"
  
  while [[ $attempt -le $max_attempts ]]; do
    log_message "info" "API call attempt $attempt of $max_attempts"
    
    if eval "$command"; then
      return 0
    fi
    
    if [[ $attempt -lt $max_attempts ]]; then
      log_message "warning" "Attempt $attempt failed, retrying in ${delay}s..."
      sleep $delay
      delay=$((delay * 2))  # Exponential backoff
    fi
    
    ((attempt++))
  done
  
  log_message "error" "All $max_attempts attempts failed"
  return 1
}

# Check for required dependencies
check_dependencies() {
  log_message "info" "Checking dependencies..."
  check_command "curl"
  check_command "jq"  # For JSON parsing
}

# Check if API key is valid by making a test request
test_claude_api_key() {
  local api_key="$1"
  
  log_message "info" "Testing Claude API key..."
  
  # Simple test request to Claude API with retry logic
  retry_api_call "curl -s -S -f -o /dev/null -w '%{http_code}' \
    -H 'x-api-key: ${api_key}' \
    -H 'anthropic-version: ${CLAUDE_VERSION}' \
    '${CLAUDE_API_URL}/v1/models' 2>/dev/null | grep -q '200'"
}

# Check if OpenAI API key is valid
test_openai_api_key() {
  local api_key="$1"
  
  log_message "info" "Testing OpenAI API key..."
  
  # Simple test request to OpenAI API with retry logic
  retry_api_call "curl -s -S -f -o /dev/null -w '%{http_code}' \
    -H 'Authorization: Bearer ${api_key}' \
    '${OPENAI_API_URL}/v1/models' 2>/dev/null | grep -q '200'"
}

# Check if Goose API key is valid
test_goose_api_key() {
  local api_key="$1"
  
  log_message "info" "Testing Goose AI API key..."
  
  # Simple test request to Goose API with retry logic
  retry_api_call "curl -s -S -f -o /dev/null -w '%{http_code}' \
    -H 'Authorization: Bearer ${api_key}' \
    '${GOOSE_API_URL}/v1/engines' 2>/dev/null | grep -q '200'"
}

# Update Claude API key
update_claude_api_key() {
  log_message "info" "Updating Claude API key..."
  
  local current_key=""
  # Check environment variable first
  if [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
    current_key="$ANTHROPIC_API_KEY"
    log_message "info" "Using API key from ANTHROPIC_API_KEY environment variable"
  elif [[ -f "${CLAUDE_CONFIG}" ]]; then
    current_key=$(jq -r '.api_key // ""' "${CLAUDE_CONFIG}" 2>/dev/null || echo "")
  fi
  
  # Prompt for new API key or use existing
  local prompt="Enter your Claude API key"
  if [[ -n "$current_key" ]]; then
    prompt="${prompt} (leave empty to keep current key)"
  fi
  
  echo -n "${prompt}: "
  read -r api_key
  
  # If empty and we have an existing key, keep using it
  if [[ -z "$api_key" && -n "$current_key" ]]; then
    log_message "info" "Keeping existing Claude API key"
    api_key="$current_key"
  elif [[ -z "$api_key" && -z "$current_key" ]]; then
    fail "No API key provided and no existing key found"
  fi
  
  # Test the API key
  if ! test_claude_api_key "$api_key"; then
    log_message "warning" "The provided Claude API key appears to be invalid"
    echo -n "Do you want to continue anyway? (y/N): "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
      fail "Aborting due to invalid API key"
    fi
  fi
  
  # Create or update the configuration file
  jq -n --arg key "$api_key" --arg updated "$(date +%Y-%m-%d)" \
    '{"api_key": $key, "last_updated": $updated}' > "${CLAUDE_CONFIG}" \
    || fail "Failed to update Claude configuration file"
  
  chmod 600 "${CLAUDE_CONFIG}"  # Secure the API key file
  log_message "success" "Claude API key updated successfully"
}

# Update OpenAI API key
update_openai_api_key() {
  log_message "info" "Updating OpenAI API key..."
  
  local current_key=""
  # Check environment variable first
  if [[ -n "${OPENAI_API_KEY:-}" ]]; then
    current_key="$OPENAI_API_KEY"
    log_message "info" "Using API key from OPENAI_API_KEY environment variable"
  elif [[ -f "${OPENAI_CONFIG}" ]]; then
    current_key=$(jq -r '.api_key // ""' "${OPENAI_CONFIG}" 2>/dev/null || echo "")
  fi
  
  # Prompt for new API key or use existing
  local prompt="Enter your OpenAI API key"
  if [[ -n "$current_key" ]]; then
    prompt="${prompt} (leave empty to keep current key)"
  fi
  
  echo -n "${prompt}: "
  read -r api_key
  
  # If empty and we have an existing key, keep using it
  if [[ -z "$api_key" && -n "$current_key" ]]; then
    log_message "info" "Keeping existing OpenAI API key"
    api_key="$current_key"
  elif [[ -z "$api_key" && -z "$current_key" ]]; then
    fail "No API key provided and no existing key found"
  fi
  
  # Test the API key
  if ! test_openai_api_key "$api_key"; then
    log_message "warning" "The provided OpenAI API key appears to be invalid"
    echo -n "Do you want to continue anyway? (y/N): "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
      fail "Aborting due to invalid API key"
    fi
  fi
  
  # Create or update the configuration file
  jq -n --arg key "$api_key" --arg model "$OPENAI_CODEX_MODEL" --arg updated "$(date +%Y-%m-%d)" \
    '{"api_key": $key, "model": $model, "last_updated": $updated}' > "${OPENAI_CONFIG}" \
    || fail "Failed to update OpenAI configuration file"
  
  chmod 600 "${OPENAI_CONFIG}"  # Secure the API key file
  log_message "success" "OpenAI API key updated successfully"
}

# Update Goose API key
update_goose_api_key() {
  log_message "info" "Updating Goose AI API key..."
  
  local current_key=""
  # Check environment variable first
  if [[ -n "${GOOSE_API_KEY:-}" ]]; then
    current_key="$GOOSE_API_KEY"
    log_message "info" "Using API key from GOOSE_API_KEY environment variable"
  elif [[ -f "${GOOSE_CONFIG}" ]]; then
    current_key=$(jq -r '.api_key // ""' "${GOOSE_CONFIG}" 2>/dev/null || echo "")
  fi
  
  # Prompt for new API key or use existing
  local prompt="Enter your Goose AI API key"
  if [[ -n "$current_key" ]]; then
    prompt="${prompt} (leave empty to keep current key)"
  fi
  
  echo -n "${prompt}: "
  read -r api_key
  
  # If empty and we have an existing key, keep using it
  if [[ -z "$api_key" && -n "$current_key" ]]; then
    log_message "info" "Keeping existing Goose AI API key"
    api_key="$current_key"
  elif [[ -z "$api_key" && -z "$current_key" ]]; then
    fail "No API key provided and no existing key found"
  fi
  
  # Test the API key
  if ! test_goose_api_key "$api_key"; then
    log_message "warning" "The provided Goose AI API key appears to be invalid"
    echo -n "Do you want to continue anyway? (y/N): "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
      fail "Aborting due to invalid API key"
    fi
  fi
  
  # Create or update the configuration file
  jq -n --arg key "$api_key" --arg model "$GOOSE_MODEL" --arg updated "$(date +%Y-%m-%d)" \
    '{"api_key": $key, "model": $model, "last_updated": $updated}' > "${GOOSE_CONFIG}" \
    || fail "Failed to update Goose AI configuration file"
  
  chmod 600 "${GOOSE_CONFIG}"  # Secure the API key file
  log_message "success" "Goose AI API key updated successfully"
}

# Update Claude AI
update_claude() {
  log_message "info" "Updating Claude AI..."
  
  # Check if we need to update API key
  if [[ "$UPDATE_KEYS" == "true" ]]; then
    update_claude_api_key
  fi
  
  # Fetch available Claude models
  if [[ -f "${CLAUDE_CONFIG}" ]]; then
    local api_key
    api_key=$(jq -r '.api_key' "${CLAUDE_CONFIG}" 2>/dev/null)
    
    if [[ -n "$api_key" ]]; then
      log_message "info" "Checking available Claude models..."
      
      local models_response
      models_response=$(curl -s -S -f \
        -H "x-api-key: ${api_key}" \
        -H "anthropic-version: ${CLAUDE_VERSION}" \
        "${CLAUDE_API_URL}/v1/models" 2>/dev/null || echo '{"error": "Failed to fetch models"}')
      
      if echo "$models_response" | jq -e '.error' >/dev/null 2>&1; then
        log_message "warning" "Failed to fetch Claude models: $(echo "$models_response" | jq -r '.error')"
      else
        echo "Available Claude models:"
        echo "$models_response" | jq -r '.models[] | "  " + .name + " (" + .description + ")"' | sort
        
        # Update the preferred model if requested
        echo -n "Would you like to update your preferred Claude model? (y/N): "
        read -r update_model
        
        if [[ "$update_model" =~ ^[Yy]$ ]]; then
          echo -n "Enter the model name (e.g., claude-3-opus-20240229): "
          read -r model_name
          
          # Verify the model exists
          if echo "$models_response" | jq -e ".models[] | select(.name == \"$model_name\")" >/dev/null 2>&1; then
            # Update the configuration with the new model
            jq --arg model "$model_name" '.preferred_model = $model' "${CLAUDE_CONFIG}" > "${CLAUDE_CONFIG}.tmp" \
              && mv "${CLAUDE_CONFIG}.tmp" "${CLAUDE_CONFIG}" \
              || fail "Failed to update Claude configuration"
            
            log_message "success" "Updated preferred Claude model to: $model_name"
          else
            log_message "error" "Invalid model name: $model_name"
          fi
        fi
      fi
    else
      log_message "warning" "Claude API key not found. Run with --keys option to update."
    fi
  else
    log_message "warning" "Claude configuration not found. Run with --keys option to set up."
  fi
  
  # Update Claude dependencies if Claude Code is installed
  if [[ -d "$HOME/.claude/local" ]]; then
    log_message "info" "Updating Claude dependencies..."
    (cd "$HOME/.claude/local" && npm update @anthropic-ai/claude-code) || log_message "warning" "Failed to update Claude dependencies - may not be installed"
  else
    log_message "info" "Claude Code local installation not found - skipping dependency update"
  fi
}

# Update OpenAI Codex
update_openai() {
  log_message "info" "Updating OpenAI Codex..."
  
  # Check if we need to update API key
  if [[ "$UPDATE_KEYS" == "true" ]]; then
    update_openai_api_key
  fi
  
  # Fetch available OpenAI models
  if [[ -f "${OPENAI_CONFIG}" ]]; then
    local api_key
    api_key=$(jq -r '.api_key' "${OPENAI_CONFIG}" 2>/dev/null)
    
    if [[ -n "$api_key" ]]; then
      log_message "info" "Checking available OpenAI code models..."
      
      local models_response
      models_response=$(curl -s -S -f \
        -H "Authorization: Bearer ${api_key}" \
        "${OPENAI_API_URL}/v1/models" 2>/dev/null || echo '{"error": "Failed to fetch models"}')
      
      if echo "$models_response" | jq -e '.error' >/dev/null 2>&1; then
        log_message "warning" "Failed to fetch OpenAI models: $(echo "$models_response" | jq -r '.error.message // .error')"
      else
        echo "Available OpenAI code models:"
        echo "$models_response" | jq -r '.data[] | select(.id | contains("code") or contains("davinci")) | "  " + .id' | sort
        
        # Update the preferred model if requested
        echo -n "Would you like to update your preferred OpenAI code model? (y/N): "
        read -r update_model
        
        if [[ "$update_model" =~ ^[Yy]$ ]]; then
          echo -n "Enter the model name (e.g., code-davinci-002): "
          read -r model_name
          
          # Verify the model exists
          if echo "$models_response" | jq -e ".data[] | select(.id == \"$model_name\")" >/dev/null 2>&1; then
            # Update the configuration with the new model
            jq --arg model "$model_name" '.model = $model' "${OPENAI_CONFIG}" > "${OPENAI_CONFIG}.tmp" \
              && mv "${OPENAI_CONFIG}.tmp" "${OPENAI_CONFIG}" \
              || fail "Failed to update OpenAI configuration"
            
            log_message "success" "Updated preferred OpenAI model to: $model_name"
          else
            log_message "error" "Invalid model name: $model_name"
          fi
        fi
      fi
    else
      log_message "warning" "OpenAI API key not found. Run with --keys option to update."
    fi
  else
    log_message "warning" "OpenAI configuration not found. Run with --keys option to set up."
  fi
}

# Update Goose AI
update_goose() {
  log_message "info" "Updating Goose AI..."
  
  # Check if we need to update API key
  if [[ "$UPDATE_KEYS" == "true" ]]; then
    update_goose_api_key
  fi
  
  # Fetch available Goose models
  if [[ -f "${GOOSE_CONFIG}" ]]; then
    local api_key
    api_key=$(jq -r '.api_key' "${GOOSE_CONFIG}" 2>/dev/null)
    
    if [[ -n "$api_key" ]]; then
      log_message "info" "Checking available Goose AI models..."
      
      local models_response
      models_response=$(curl -s -S -f \
        -H "Authorization: Bearer ${api_key}" \
        "${GOOSE_API_URL}/v1/engines" 2>/dev/null || echo '{"error": "Failed to fetch engines"}')
      
      if echo "$models_response" | jq -e '.error' >/dev/null 2>&1; then
        log_message "warning" "Failed to fetch Goose models: $(echo "$models_response" | jq -r '.error.message // .error')"
      else
        echo "Available Goose AI engines:"
        echo "$models_response" | jq -r '.data[]? | "  " + .id' | sort
        
        # Update the preferred model if requested
        echo -n "Would you like to update your preferred Goose AI model? (y/N): "
        read -r update_model
        
        if [[ "$update_model" =~ ^[Yy]$ ]]; then
          echo -n "Enter the engine name (e.g., gpt-neo-20b): "
          read -r model_name
          
          # Verify the model exists
          if echo "$models_response" | jq -e ".data[]? | select(.id == \"$model_name\")" >/dev/null 2>&1; then
            # Update the configuration with the new model
            jq --arg model "$model_name" '.model = $model' "${GOOSE_CONFIG}" > "${GOOSE_CONFIG}.tmp" \
              && mv "${GOOSE_CONFIG}.tmp" "${GOOSE_CONFIG}" \
              || fail "Failed to update Goose AI configuration"
            
            log_message "success" "Updated preferred Goose AI model to: $model_name"
          else
            log_message "error" "Invalid model name: $model_name"
          fi
        fi
      fi
    else
      log_message "warning" "Goose AI API key not found. Run with --keys option to update."
    fi
  else
    log_message "warning" "Goose AI configuration not found. Run with --keys option to set up."
  fi
}

# Check status of all services
check_status() {
  log_message "info" "Checking current status of AI coding services..."
  
  # Check Claude status
  echo -e "\n${BOLD}Claude AI Status:${RESET}"
  if [[ -f "${CLAUDE_CONFIG}" ]]; then
    local claude_key claude_model claude_updated
    claude_key=$(jq -r '.api_key // "Not configured"' "${CLAUDE_CONFIG}" 2>/dev/null)
    claude_model=$(jq -r '.preferred_model // "Not set"' "${CLAUDE_CONFIG}" 2>/dev/null)
    claude_updated=$(jq -r '.last_updated // "Unknown"' "${CLAUDE_CONFIG}" 2>/dev/null)
    
    echo "API Key: ${claude_key:0:5}...${claude_key: -5}" # Show first/last 5 chars only
    echo "Preferred Model: $claude_model"
    echo "Last Updated: $claude_updated"
    
    # Test the API key
    if test_claude_api_key "$claude_key" 2>/dev/null; then
      echo -e "API Status: ${GREEN}Active${RESET}"
    else
      echo -e "API Status: ${RED}Invalid or expired${RESET}"
    fi
  else
    echo "Claude is not configured. Run with --claude --keys to set up."
  fi
  
  # Check OpenAI status
  echo -e "\n${BOLD}OpenAI Codex Status:${RESET}"
  if [[ -f "${OPENAI_CONFIG}" ]]; then
    local openai_key openai_model openai_updated
    openai_key=$(jq -r '.api_key // "Not configured"' "${OPENAI_CONFIG}" 2>/dev/null)
    openai_model=$(jq -r '.model // "Not set"' "${OPENAI_CONFIG}" 2>/dev/null)
    openai_updated=$(jq -r '.last_updated // "Unknown"' "${OPENAI_CONFIG}" 2>/dev/null)
    
    echo "API Key: ${openai_key:0:5}...${openai_key: -5}" # Show first/last 5 chars only
    echo "Preferred Model: $openai_model"
    echo "Last Updated: $openai_updated"
    
    # Test the API key
    if test_openai_api_key "$openai_key" 2>/dev/null; then
      echo -e "API Status: ${GREEN}Active${RESET}"
    else
      echo -e "API Status: ${RED}Invalid or expired${RESET}"
    fi
  else
    echo "OpenAI is not configured. Run with --openai --keys to set up."
  fi
  
  # Check Goose AI status
  echo -e "\n${BOLD}Goose AI Status:${RESET}"
  if [[ -f "${GOOSE_CONFIG}" ]]; then
    local goose_key goose_model goose_updated
    goose_key=$(jq -r '.api_key // "Not configured"' "${GOOSE_CONFIG}" 2>/dev/null)
    goose_model=$(jq -r '.model // "Not set"' "${GOOSE_CONFIG}" 2>/dev/null)
    goose_updated=$(jq -r '.last_updated // "Unknown"' "${GOOSE_CONFIG}" 2>/dev/null)
    
    echo "API Key: ${goose_key:0:5}...${goose_key: -5}" # Show first/last 5 chars only
    echo "Preferred Model: $goose_model"
    echo "Last Updated: $goose_updated"
    
    # Test the API key
    if test_goose_api_key "$goose_key" 2>/dev/null; then
      echo -e "API Status: ${GREEN}Active${RESET}"
    else
      echo -e "API Status: ${RED}Invalid or expired${RESET}"
    fi
  else
    echo "Goose AI is not configured. Run with --goose --keys to set up."
  fi
}

# Display usage information
show_help() {
  cat << EOF
Usage: $(basename "$0") [options]

This script helps you update and manage Claude AI, OpenAI Codex, and Goose AI API access.

Options:
  -c, --claude        Update Claude AI only
  -o, --openai        Update OpenAI Codex only
  -g, --goose         Update Goose AI only
  -a, --all           Update all services (default)
  -k, --keys          Update API keys only
  -s, --status        Check current status of all services
      --cleanup       Clean up temporary files and logs
  -h, --help          Display this help message

Examples:
  $(basename "$0") --all     # Update all services
  $(basename "$0") -s        # Check status only
  $(basename "$0") -c -k     # Update Claude API keys only
  $(basename "$0") -g        # Update Goose AI only
  $(basename "$0") --cleanup # Clean up temporary files
EOF
}

# Display interactive menu
show_menu() {
  clear
  echo -e "${BOLD}AI Code Updater${RESET} - Manage Claude, OpenAI, and Goose AI"
  echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
  
  echo -e "${BOLD}### Options${RESET}\n"
  echo -e "┌───────────────┬─────────────────────────────────────┐"
  echo -e "│ ${BOLD}Option${RESET}        │ ${BOLD}Description${RESET}                     │"
  echo -e "├───────────────┼─────────────────────────────────────┤"
  echo -e "│ 1. All        │ Update all services                 │"
  echo -e "│ 2. Claude     │ Update Claude AI only              │"
  echo -e "│ 3. OpenAI     │ Update OpenAI Codex only           │"
  echo -e "│ 4. Goose      │ Update Goose AI only               │"
  echo -e "│ 5. Keys       │ Update API keys only               │"
  echo -e "│ 6. Status     │ Check current status of services   │"
  echo -e "│ 7. Cleanup    │ Clean up temporary files and logs  │"
  echo -e "│ 8. Help       │ Display command-line help          │"
  echo -e "│ 0. Exit       │ Exit the program                   │"
  echo -e "└───────────────┴─────────────────────────────────────┘\n"
  
  echo -e "Command-line options are also available:"
  echo -e "  -c, --claude   │  -o, --openai   │  -g, --goose"
  echo -e "  -a, --all      │  -k, --keys     │  -s, --status\n"
  
  echo -n "Enter your choice [0-8]: "
  read -r choice
  
  case "$choice" in
    1)
      UPDATE_CLAUDE=true
      UPDATE_OPENAI=true
      UPDATE_GOOSE=true
      ;;
    2)
      UPDATE_CLAUDE=true
      ;;
    3)
      UPDATE_OPENAI=true
      ;;
    4)
      UPDATE_GOOSE=true
      ;;
    5)
      if ! check_keys_option; then
        return 1
      fi
      ;;
    6)
      CHECK_STATUS=true
      ;;
    7)
      log_state "system" "cleanup" "started" "Manual cleanup initiated"
      update_documentation "Manual cleanup performed"
      cleanup_files
      log_state "system" "cleanup" "completed" "Manual cleanup completed"
      echo -e "\nPress Enter to return to menu..."
      read -r
      show_menu
      return $?
      ;;
    8)
      show_help
      echo -e "\nPress Enter to return to menu..."
      read -r
      show_menu
      return $?
      ;;
    0)
      echo "Exiting..."
      exit 0
      ;;
    *)
      log_message "error" "Invalid option: $choice"
      echo "Press Enter to continue..."
      read -r
      show_menu
      return $?
      ;;
  esac
  
  return 0
}

# Check if keys option needs service selection
check_keys_option() {
  echo -e "\n${BOLD}Which service keys do you want to update?${RESET}"
  echo "1. All services (Claude, OpenAI, and Goose)"
  echo "2. Claude only"
  echo "3. OpenAI only"
  echo "4. Goose AI only"
  echo "0. Back to main menu"
  
  echo -n "Enter your choice [0-4]: "
  read -r key_choice
  
  case "$key_choice" in
    1)
      UPDATE_CLAUDE=true
      UPDATE_OPENAI=true
      UPDATE_GOOSE=true
      UPDATE_KEYS=true
      ;;
    2)
      UPDATE_CLAUDE=true
      UPDATE_KEYS=true
      ;;
    3)
      UPDATE_OPENAI=true
      UPDATE_KEYS=true
      ;;
    4)
      UPDATE_GOOSE=true
      UPDATE_KEYS=true
      ;;
    0)
      show_menu
      return $?
      ;;
    *)
      log_message "error" "Invalid option: $key_choice"
      echo "Press Enter to continue..."
      read -r
      return 1
      ;;
  esac
  
  return 0
}

# Main function
main() {
  # Track if we're in interactive mode (via menu)
  local interactive_mode=false
  
  # Default values
  UPDATE_CLAUDE=false
  UPDATE_OPENAI=false
  UPDATE_GOOSE=false
  UPDATE_KEYS=false
  CHECK_STATUS=false
  CLEANUP_FILES=false
  
  # Parse command line arguments if provided
  if [[ $# -gt 0 ]]; then
    while [[ $# -gt 0 ]]; do
      case "$1" in
        -c|--claude)
          UPDATE_CLAUDE=true
          shift
          ;;
        -o|--openai)
          UPDATE_OPENAI=true
          shift
          ;;
        -g|--goose)
          UPDATE_GOOSE=true
          shift
          ;;
        -a|--all)
          UPDATE_CLAUDE=true
          UPDATE_OPENAI=true
          UPDATE_GOOSE=true
          shift
          ;;
        -k|--keys)
          UPDATE_KEYS=true
          shift
          ;;
        -s|--status)
          CHECK_STATUS=true
          shift
          ;;
        --cleanup)
          CLEANUP_FILES=true
          shift
          ;;
        -h|--help)
          show_help
          exit 0
          ;;
        *)
          log_message "error" "Unknown option: $1"
          show_help
          exit 1
          ;;
      esac
    done
  else
    # No arguments provided, we're in interactive mode
    interactive_mode=true
    # Show the interactive menu
    show_menu || show_menu  # Show menu again if there was an error
  fi
  
  # If keys were requested but no service specified, default to all
  if [[ "$UPDATE_KEYS" == "true" && "$UPDATE_CLAUDE" == "false" && "$UPDATE_OPENAI" == "false" && "$UPDATE_GOOSE" == "false" ]]; then
    UPDATE_CLAUDE=true
    UPDATE_OPENAI=true
    UPDATE_GOOSE=true
  fi
  
  # Check dependencies
  check_dependencies
  
  # Ensure configuration directory exists
  ensure_config_dir
  
  # Initialize git support
  init_git_support
  
  # Clean up old files
  cleanup_files
  
  # Check status if requested
  if [[ "$CHECK_STATUS" == "true" ]]; then
    log_state "system" "status_check" "started" "Checking status of all services"
    update_documentation "Status check performed"
    check_status
    log_state "system" "status_check" "completed" "Status check completed successfully"
    
    # If we're in interactive mode, wait for user input before returning to menu
    if [[ "$interactive_mode" == "true" ]]; then
      echo -e "\nPress Enter to continue..."
      read -r
      show_menu
    fi
    
    exit 0
  fi
  
  # Handle cleanup if requested
  if [[ "$CLEANUP_FILES" == "true" ]]; then
    log_state "system" "cleanup" "started" "Command-line cleanup initiated"
    update_documentation "Command-line cleanup performed"
    cleanup_files
    log_state "system" "cleanup" "completed" "Command-line cleanup completed"
    exit 0
  fi
  
  # Update the requested services
  if [[ "$UPDATE_CLAUDE" == "true" ]]; then
    log_state "claude" "update" "started" "Starting Claude AI update"
    update_claude
    log_state "claude" "update" "completed" "Claude AI update completed"
  fi
  
  if [[ "$UPDATE_OPENAI" == "true" ]]; then
    log_state "openai" "update" "started" "Starting OpenAI update"
    update_openai
    log_state "openai" "update" "completed" "OpenAI update completed"
  fi
  
  if [[ "$UPDATE_GOOSE" == "true" ]]; then
    log_state "goose" "update" "started" "Starting Goose AI update"
    update_goose
    log_state "goose" "update" "completed" "Goose AI update completed"
  fi
  
  # Log overall completion and update documentation
  log_state "system" "update_all" "completed" "All requested services updated successfully"
  update_documentation "Updated AI services: Claude=$UPDATE_CLAUDE, OpenAI=$UPDATE_OPENAI, Goose=$UPDATE_GOOSE"
  commit_changes "Updated AI services configuration and state"
  
  log_message "success" "All updates completed successfully"
  
  # If we're in interactive mode, wait for user input before returning to menu
  if [[ "$interactive_mode" == "true" ]]; then
    echo -e "\nPress Enter to return to menu..."
    read -r
    show_menu
  fi
}

# Call the main function
main "$@"