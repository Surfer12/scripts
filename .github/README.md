# 🧠 Meta-Optimized Hybrid Reasoning Framework  
**by Ryan Oates**  
**License: Dual — AGPLv3 + Peer Production License (PPL)**  
**Contact: ryan_oates@my.cuesta.edu**

---

## ✨ Purpose

This framework is part of an interdisciplinary vision to combine **symbolic rigor**, **neural adaptability**, and **cognitive-aligned reasoning**. It reflects years of integrated work at the intersection of computer science, biopsychology, and meta-epistemology.

It is not just software. It is a **cognitive architecture**, and its use is **ethically bounded**.

---

## 🔐 Licensing Model

This repository is licensed under a **hybrid model** to balance openness, reciprocity, and authorship protection.

### 1. For Commons-Aligned Users (students, researchers, cooperatives)
Use it under the **Peer Production License (PPL)**. You can:
- Study, adapt, and share it freely
- Use it in academic or nonprofit research
- Collaborate openly within the digital commons

### 2. For Public Use and Transparency
The AGPLv3 license guarantees:
- Network-based deployments must share modifications
- Derivatives must remain open source
- Attribution is mandatory

### 3. For Commercial or Extractive Use
You **must not use this work** if you are a:
- For-profit AI company
- Venture-backed foundation
- Closed-source platform
...unless you **negotiate a commercial license** directly.

---

## 📚 Attribution

This framework originated in:

> *Meta-Optimization in Hybrid Theorem Proving: Cognitive-Constrained Reasoning Framework*, Ryan Oates (2025)

DOI: [Insert Zenodo/ArXiv link here]  
Git commit hash of original release: `a17c3f9...`  
This project’s cognitive-theoretic roots come from studies in:
- Flow state modeling
- Symbolic logic systems
- Jungian epistemological structures

---

## 🤝 Community Contributor Agreement

If you are a student, educator, or aligned research group and want to contribute:
1. Fork this repo
2. Acknowledge the author and original framework
3. Use the “Contributors.md” file to describe your adaptation
4. Optional: Sign and return the [Community Contributor Agreement (CCA)](link) to join the federated research network

---

## 🚫 What You May Not Do

- Integrate this system into closed-source LLM deployments
- Resell it or offer derivative products without explicit approval
- Strip author tags or alter authorship metadata

---

## 📬 Contact

Want to collaborate, cite properly, or license commercially?  
Reach out: **ryan_oates@my.cuesta.edu**
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