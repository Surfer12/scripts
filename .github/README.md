# GitHub Actions & Dependabot Configuration

This directory contains GitHub Actions workflows and Dependabot configuration for automated dependency management and continuous integration.

## Files

### Workflows

#### `dependabot-auto-merge.yml`
Automatically merges Dependabot pull requests when tests pass. This workflow:
- Triggers only on PRs created by Dependabot
- Runs the full test suite using pytest
- Auto-merges the PR if all tests pass
- Requires the `contents: write` and `pull-requests: write` permissions

#### `ci.yml`
Continuous Integration workflow that runs on all PRs and pushes to main/master:
- Tests against Python 3.10, 3.11, and 3.12
- Installs dependencies from `requirements.txt`
- Runs pytest with verbose output
- Validates that main application modules can be imported

### Configuration

#### `dependabot.yml`
Configures Dependabot to automatically create PRs for dependency updates:
- **Python dependencies**: Weekly updates on Mondays at 9 AM
- **GitHub Actions**: Weekly updates on Mondays at 9 AM
- Assigns PRs to `Surfer12` for review
- Limits open PRs to prevent spam (10 for pip, 5 for GitHub Actions)
- Uses semantic commit prefixes (`deps:` for Python, `ci:` for Actions)

## Security Considerations

The auto-merge workflow only runs for Dependabot PRs and requires all tests to pass before merging. This ensures that:
1. Only trusted dependency updates are auto-merged
2. Breaking changes are caught by the test suite
3. Manual review is still possible if tests fail

## Setup Requirements

For the auto-merge functionality to work, ensure:
1. The repository has branch protection rules that require status checks
2. The `GITHUB_TOKEN` has sufficient permissions (automatically provided by GitHub)
3. Tests are comprehensive enough to catch breaking changes

## Customization

To modify the auto-merge behavior:
- Edit the test command in `dependabot-auto-merge.yml`
- Adjust the Dependabot schedule in `dependabot.yml`
- Add additional checks or conditions as needed