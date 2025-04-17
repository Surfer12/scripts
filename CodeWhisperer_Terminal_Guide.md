# Using Amazon CodeWhisperer in the Terminal (macOS with zsh)

This guide explains how to set up and use Amazon CodeWhisperer in your terminal environment on macOS with zsh.

## What is Amazon CodeWhisperer?

Amazon CodeWhisperer is an AI-powered coding companion that provides real-time code suggestions and helps you write code faster and with fewer errors. It can be integrated into your terminal environment to assist with command-line tasks and scripting.

## Installation

### Prerequisites

- macOS operating system
- zsh shell (default on modern macOS)
- AWS CLI installed and configured
- Node.js and npm (for the CodeWhisperer CLI)

### Step 1: Install the CodeWhisperer CLI

```bash
# Install the CodeWhisperer CLI globally
npm install -g @aws/codewhisperer-cli
```

### Step 2: Configure AWS Credentials

Ensure your AWS credentials are properly configured:

```bash
aws configure
```

### Step 3: Set Up zsh Integration

Add the following to your `~/.zshrc` file:

```bash
# CodeWhisperer integration
if command -v codewhisperer &> /dev/null; then
  source <(codewhisperer completion zsh)
  
  # Optional: Create an alias for easier access
  alias cw="codewhisperer"
  
  # Enable inline suggestions (if supported)
  export CODEWHISPERER_INLINE_SUGGESTIONS=true
fi
```

After adding these lines, reload your zsh configuration:

```bash
source ~/.zshrc
```

## Basic Usage

### Getting Started

Verify the installation:

```bash
codewhisperer --version
```

Authenticate with your AWS account:

```bash
codewhisperer auth
```

### Command-Line Suggestions

CodeWhisperer can provide suggestions as you type in the terminal:

1. Start typing a command
2. Press `Tab` to see suggestions (or the configured key binding)
3. Accept a suggestion with `Enter` or continue typing to refine

### Script Assistance

When editing shell scripts in the terminal:

```bash
# Open a new script with CodeWhisperer assistance
codewhisperer edit new_script.sh
```

## Advanced Features

### Custom Prompts

You can use custom prompts to get specific code suggestions:

```bash
codewhisperer generate "Write a zsh function to find and delete empty directories"
```

### Context-Aware Suggestions

CodeWhisperer analyzes your current directory and recent commands to provide more relevant suggestions:

```bash
# Enable context awareness
export CODEWHISPERER_CONTEXT_AWARE=true
```

### Security Scanning

Scan your scripts for security issues:

```bash
codewhisperer scan my_script.sh
```

## Configuration Options

Create a configuration file at `~/.codewhisperer/config.json`:

```json
{
  "theme": "dark",
  "suggestionDelay": 300,
  "maxSuggestions": 5,
  "telemetry": false,
  "logLevel": "info"
}
```

## Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Accept suggestion | `Tab` or `Right Arrow` |
| Next suggestion | `Alt+]` |
| Previous suggestion | `Alt+[` |
| Dismiss suggestion | `Esc` |
| Request suggestion | `Alt+\` |

## Troubleshooting

### Common Issues

1. **Authentication failures**:
   ```bash
   aws sso login
   codewhisperer auth --refresh
   ```

2. **Suggestions not appearing**:
   ```bash
   # Check if the service is running
   codewhisperer status
   
   # Restart the service
   codewhisperer restart
   ```

3. **Performance issues**:
   ```bash
   # Reduce context size
   export CODEWHISPERER_CONTEXT_SIZE=medium
   ```

### Logs

Check logs for troubleshooting:

```bash
cat ~/.codewhisperer/logs/codewhisperer.log
```

## Best Practices

1. **Keep CodeWhisperer updated**:
   ```bash
   npm update -g @aws/codewhisperer-cli
   ```

2. **Use project-specific settings**:
   Create a `.codewhisperer` file in your project directory with custom settings.

3. **Combine with other tools**:
   CodeWhisperer works well alongside tools like `fzf`, `tldr`, and `bat`.

4. **Create aliases for common tasks**:
   ```bash
   # Add to ~/.zshrc
   alias cwg="codewhisperer generate"
   alias cws="codewhisperer scan"
   ```

## Resources

- [Official CodeWhisperer Documentation](https://docs.aws.amazon.com/codewhisperer/)
- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/)
- [zsh Documentation](https://zsh.sourceforge.io/Doc/)

## Support

For issues or questions:
- Visit the [AWS Developer Forums](https://forums.aws.amazon.com/)
- Open an issue on the [GitHub repository](https://github.com/aws/aws-codewhisperer-cli)
- Contact AWS Support if you have an AWS support plan
