# Homebrew Maintenance Guide

This document provides instructions for maintaining your Homebrew installation and packages.

## Initial Setup

### Installing Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Using the Brewfile

A Brewfile is included in this repository to ensure consistent environment setup. To install all packages:

```bash
brew bundle install
```

To create/update the Brewfile based on your currently installed packages:

```bash
brew bundle dump --force
```

## Regular Maintenance

### Daily/Weekly Maintenance

Run the included `homebrew_security.sh` script:

```bash
./homebrew_security.sh
```

This script performs:
- Updates Homebrew formulae
- Upgrades outdated packages
- Cleans up old versions and cached downloads
- Checks for security vulnerabilities

### Manual Maintenance Commands

#### Update Homebrew

```bash
brew update
```

#### Upgrade Packages

```bash
brew upgrade
```

To upgrade specific packages:

```bash
brew upgrade [package_name]
```

#### Cleanup Old Versions

```bash
brew cleanup
```

For a dry run (see what would be cleaned up without actually removing):

```bash
brew cleanup -n
```

#### Check for Issues

```bash
brew doctor
```

#### List Outdated Packages

```bash
brew outdated
```

#### List Dependencies

To see what depends on a specific package:

```bash
brew uses --installed [package_name]
```

#### List Installed Packages

```bash
brew list
```

For casks only:

```bash
brew list --cask
```

## Advanced Management

### Pinning Packages

To prevent a package from being upgraded:

```bash
brew pin [package_name]
```

To allow upgrades again:

```bash
brew unpin [package_name]
```

### Services Management

List services:

```bash
brew services list
```

Start a service:

```bash
brew services start [service_name]
```

Stop a service:

```bash
brew services stop [service_name]
```

Restart a service:

```bash
brew services restart [service_name]
```

## Troubleshooting

### Fix Permissions

```bash
sudo chown -R $(whoami) $(brew --prefix)/*
```

### Reset Homebrew

If you're experiencing persistent issues:

```bash
cd "$(brew --repo)"
git fetch
git reset --hard origin/master
brew update
```

### Reinstall Homebrew

In extreme cases, you might need to uninstall and reinstall:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
# Then reinstall as shown in the Installation section
```
