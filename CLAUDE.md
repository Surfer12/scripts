# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build/Lint/Test Commands
- Install dependencies: `brew bundle` (for Homebrew packages)
- Run shell scripts: `./script_name.sh [options]`
- Check for errors: `shellcheck script_name.sh`
- Format shell scripts: `shfmt -i 2 -ci -w script_name.sh`
- Test a shell script: `bash -n script_name.sh` (syntax check)
- Debug mode: Add `set -x` before problematic code sections

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