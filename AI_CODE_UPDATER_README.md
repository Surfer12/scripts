# AI Code Model Updater

This utility script helps manage and update API access to Claude AI and OpenAI Codex services. It's designed to simplify the process of keeping your AI coding assistants up-to-date and properly configured.

## Features

- **API Key Management**: Securely store and update API keys for both services
- **Model Selection**: Choose preferred models for each service
- **Status Checking**: Verify the current status of your API access
- **Service-specific Updates**: Update Claude or OpenAI individually or together

## Requirements

- bash shell
- curl
- jq (for JSON parsing)

## Usage

To use the script, simply run it without any arguments to access the interactive menu:

```bash
./ai_code_updater.sh
```

This will display a user-friendly menu with all available options.

Alternatively, you can use command-line options:

### Options

| Option | Description |
|--------|-------------|
| `-c, --claude` | Update Claude AI only |
| `-o, --openai` | Update OpenAI Codex only |
| `-a, --all` | Update both services (default) |
| `-k, --keys` | Update API keys only |
| `-s, --status` | Check current status of both services |
| `-h, --help` | Display help message |

### Examples

```bash
# Update both Claude and OpenAI
./ai_code_updater.sh --all

# Check the current status of both services
./ai_code_updater.sh -s

# Update just the Claude API key
./ai_code_updater.sh -c -k
```

## Configuration

The script stores configuration in `~/.config/ai_code/` with separate files for each service:

- `claude_config.json`: Claude AI configuration
- `openai_config.json`: OpenAI configuration

These files are created automatically and secured with appropriate permissions (600).

## Security

- API keys are stored securely with restricted file permissions
- No sensitive information is logged or displayed in full
- The script validates API keys before storing them

## Troubleshooting

### Common Issues

1. **Missing Dependencies**: Ensure `curl` and `jq` are installed
2. **Invalid API Keys**: Verify your API keys are correct and active
3. **Permission Denied**: Make sure the script is executable (`chmod +x ai_code_updater.sh`)

## Updating the Script

This script can be updated to support new models or API changes as they become available. The default Codex model is set to `code-davinci-002`, but this can be changed by updating the `OPENAI_CODEX_MODEL` variable in the script.