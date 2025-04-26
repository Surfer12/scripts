# Shell Maintenance Configuration Guide
  comprehensive markdown document (`CONFIGURATION_README.md`) in your scripts directory that explains:
- What configuration files do
- The purpose of each configuration setting
- How to create and modify configuration files
- Best practices and security considerations

The document provides a detailed guide to understanding and using the configuration file for your shell maintenance scripts. 

Key features of the documentation:
- Explains each configuration parameter
- Provides an example configuration file
- Offers guidance on creating and managing configurations
- Includes security and troubleshooting advice
## Overview

Configuration files in shell scripts provide a flexible way to customize script behavior without modifying the script itself. They allow you to:
- Set default parameters
- Enable or disable specific features
- Customize logging and notification settings
- Adapt script behavior to your specific environment

## Configuration File Locations

### Primary Configuration File
- **Path**: `~/.config/magic-shell-maintenance.conf`
- **Purpose**: Central configuration for shell maintenance scripts

### Example Configuration File

```bash
# Logging Configuration
LOG_LEVEL="info"          # Logging verbosity (debug, info, warn, error)
LOG_BASE_DIR="${HOME}/.logs"
LOG_DIR="${LOG_BASE_DIR}/shell_maintenance"
MAX_LOG_AGE_DAYS=45       # How long to keep log files

# Maintenance Workflow Controls
PERFORM_UPDATE=true       # Enable system updates
PERFORM_UPGRADE=true      # Enable system upgrades
PERFORM_SELF_UPDATE=true  # Enable self-update of maintenance tools
PERFORM_CLEANUP=true      # Enable system cleanup

# Notification Settings
SEND_NOTIFICATIONS=true   # Enable email notifications
NOTIFICATION_METHOD="email"
NOTIFICATION_RECIPIENT="your_email@example.com"

# Maintenance Timeouts and Security
COMMAND_TIMEOUT=900       # 15 minutes max for maintenance tasks
SECURITY_SCAN_LEVEL="standard"  # Security scan intensity

# Package Management
IGNORE_PACKAGES=("python2" "ruby-old" "perl5.18")
FORCE_UPDATE_PACKAGES=("python" "nodejs" "git")

# Cleanup Paths
CLEANUP_PATHS=(
    "${HOME}/.cache/pip"
    "${HOME}/.npm"
    "${HOME}/Library/Caches"
    "${HOME}/Downloads"
    "/tmp"
)

EXCLUDE_CLEANUP_PATHS=(
    "${HOME}/Projects"
    "${HOME}/.ssh"
    "${HOME}/.gnupg"
)
```

## Configuration Parameters Explained

### Logging Configuration
- `LOG_LEVEL`: Controls the verbosity of logging
  - `debug`: Most verbose, logs everything
  - `info`: Standard logging, excludes debug messages
  - `warn`: Only logs warnings and errors
  - `error`: Only logs critical errors

- `LOG_BASE_DIR`: Base directory for log files
- `LOG_DIR`: Specific subdirectory for maintenance logs
- `MAX_LOG_AGE_DAYS`: Automatically removes log files older than specified days

### Maintenance Workflow Controls
Boolean flags to enable/disable specific maintenance tasks:
- `PERFORM_UPDATE`: Run system updates
- `PERFORM_UPGRADE`: Perform system package upgrades
- `PERFORM_SELF_UPDATE`: Update maintenance tools themselves
- `PERFORM_CLEANUP`: Clean up temporary files and caches

### Notification Settings
- `SEND_NOTIFICATIONS`: Enable/disable email notifications
- `NOTIFICATION_METHOD`: Currently supports "email"
- `NOTIFICATION_RECIPIENT`: Email address for notifications

### Advanced Settings
- `COMMAND_TIMEOUT`: Maximum time (in seconds) for a maintenance task
- `SECURITY_SCAN_LEVEL`: Intensity of security checks
- `IGNORE_PACKAGES`: Packages to skip during updates
- `FORCE_UPDATE_PACKAGES`: Packages that should always be updated

### Cleanup Configuration
- `CLEANUP_PATHS`: Directories to clean up during maintenance
- `EXCLUDE_CLEANUP_PATHS`: Directories to preserve during cleanup

## Creating Your Configuration

1. Create the configuration directory if it doesn't exist:
   ```bash
   mkdir -p ~/.config
   ```

2. Create the configuration file:
   ```bash
   nano ~/.config/magic-shell-maintenance.conf
   ```

3. Copy the example configuration and modify to suit your needs

## Best Practices
- Always test configuration changes in a safe environment
- Regularly review and update your configuration
- Keep sensitive information (like email) secure
- Use version control for configuration files

## Troubleshooting
- If a configuration is invalid, the script will use default settings
- Check log files for any configuration-related warnings
- Ensure file permissions allow script to read the configuration

## Security Notes
- Store the configuration file with restricted permissions
  ```bash
  chmod 600 ~/.config/magic-shell-maintenance.conf
  ```
- Avoid storing sensitive credentials directly in the file

## Version Compatibility
Configuration files may change between script versions. Always:
- Check documentation when updating scripts
- Review and update your configuration accordingly