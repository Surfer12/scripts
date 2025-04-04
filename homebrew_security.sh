#!/bin/bash

# Homebrew Security Enhancement Script

# Update Homebrew and all formulae
brew update

# Upgrade all outdated packages
brew upgrade

# Clean up old versions and cached downloads
brew cleanup -s

# Check for security vulnerabilities
brew doctor

echo "Homebrew security maintenance completed on $(date)"
