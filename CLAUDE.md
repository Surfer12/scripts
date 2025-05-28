# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview
This repository contains shell scripts for system maintenance, security, and network diagnostics on macOS. The primary scripts include:

- **homebrew_security.sh**: Manages Homebrew packages with a focus on security
- **magic-modular-maintence-of-shell.sh**: Provides comprehensive shell environment maintenance
- **network_stats.sh**: Displays network configuration and statistics
- **ai_code_updater.sh**: Manages Claude AI and OpenAI Codex API access

## Build/Lint/Test Commands
- Install Pixi dependencies: `pixi install`
- Install Homebrew packages: `brew bundle` (if Brewfile exists)
- Run shell scripts: `./script_name.sh [options]`
- Check for errors: `shellcheck script_name.sh`
- Format shell scripts: `shfmt -i 2 -ci -w script_name.sh`
- Test a shell script: `bash -n script_name.sh` (syntax check)
- Debug mode: Add `set -x` before problematic code sections
- Python environment: Use `pixi run` for Python-based tasks

## Dependencies and Environment
- **Python Environment**: Managed via Pixi (see pixi.toml)
- **Key Python Packages**: openai (>=1.82.0), anthropic (>=0.52.0)
- **Platform**: macOS ARM64 (osx-arm64)
- **Shell Compatibility**: Scripts support both bash and zsh

## Main Scripts and Configuration

### Homebrew Security
- **Script**: `./homebrew/homebrew_security.sh`
- **Config**: `~/.config/homebrew_security.conf` or local `homebrew_security.conf`
- **Purpose**: Automates Homebrew updates, security audits, and cleanup
- **Usage**: `./homebrew_security.sh` or `sudo ./homebrew_security.sh` for full checks
- **Logs**: Stored in `/var/log/homebrew/`

### Magic Shell Maintenance
- **Script**: `./magic-modular-maintence-of-shell.sh`
- **Config**: `~/.config/magic-shell-maintenance.conf` or local `magic-shell-maintenance.conf`
- **Purpose**: Automates shell environment maintenance using the Modular AI "magic" command
- **Usage**: `./magic-modular-maintence-of-shell.sh`
- **Logs**: Stored in `~/.logs/shell_maintenance/`

### Network Statistics
- **Script**: `./network_stats.sh`
- **Purpose**: Displays comprehensive network information
- **Usage**: `./network_stats.sh`

### AI Code Updater
- **Script**: `./ai_code_updater.sh`
- **Config**: Created in `~/.config/ai_code/`
- **Purpose**: Manages API keys and configuration for AI coding assistants
- **Usage**: `./ai_code_updater.sh [options]` or run without arguments for interactive menu

## Code Style Guidelines
- Shell compatibility: Support both bash and zsh where possible
- Line length: 80 characters preferred
- Indentation: 2 spaces
- Error handling: Always check command return codes
- Variable names: Use UPPER_CASE for constants, lower_case for variables
- Command substitution: Prefer `$(command)` over backticks
- Functions: Include descriptive comments and error handling
- Documentation: Include usage comments at top of scripts
- File organization: Group related functions together
- Security: Avoid using `eval`, quote variables, and use `set -e`

## Script Architecture Patterns
1. **Configuration Loading**:
   - Configuration files are read from both system and local locations
   - Default configurations are provided as fallback
   - Example: `load_configuration()` function in scripts

2. **Logging System**:
   - Consistent timestamp and log level format
   - Color-coded console output when available
   - Log rotation for managing file sizes
   - Example: `log()` function in scripts

3. **Error Handling**:
   - Centralized error management functions
   - Exit codes for different error conditions
   - Optional error notifications
   - Example: `handle_error()` function in scripts

4. **Main Workflow Pattern**:
   - Pre-flight checks for dependencies and permissions
   - Primary function execution with error handling
   - Clean-up and reporting operations
   - Example: `main_workflow()` function in scripts

5. **Modular AI Integration**:
   - Scripts leverage Modular AI "magic" command for enhanced functionality
   - Python-based AI integrations through OpenAI and Anthropic APIs
   - Configuration stored in `~/.config/ai_code/` for API management