# AWS Environment Variables Helper 🌍

Easily manage and copy your AWS environment variables to the clipboard with a simple command!

## Features 🚀

- **List AWS Environment Variables**: Quickly see which AWS environment variables are exported in your current session.
- **Clipboard Support**: Automatically copies all exported AWS environment variables to your clipboard for easy pasting.

## Prerequisites 📋

Before you start, ensure you have a clipboard utility installed:
- macOS: `pbcopy` (pre-installed)
- Linux: `xclip` or `xsel` (may need to be installed)
- Windows (WSL): `clip.exe` (pre-installed)

## Installation 🛠️

1. Open your shell configuration file:
  - Bash: `~/.bashrc`
  - Zsh: `~/.zshrc`
2. Copy and paste the function definition and alias from the provided script into your configuration file.
3. Reload your shell configuration:
  - Bash: `source ~/.bashrc`
  - Zsh: `source ~/.zshrc`
  -

## Usage 📖

Simply run the following command in your terminal:

```bash
awsenv
