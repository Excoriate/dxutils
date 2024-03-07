# Set Default Application for File Extensions

Easily configure your macOS to open specific file extensions with your preferred application using the `setDefaultAppForExtensions` bash function.

## Description

This bash function automates the process of setting a default application for a list of file extensions. It's designed for macOS users who frequently work with various file types and prefer using specific applications to open them.

## Prerequisites

- macOS
- [Homebrew](https://brew.sh/)
- [duti](https://github.com/moretension/duti) (The script attempts to install `duti` automatically if it's not present)

## Installation

Add the following function to your `.bash_profile`, `.bashrc`, or `.zshrc` file:

```bash
setDefaultAppForExtensions() {
    if [ $# -lt 2 ]; then
        echo "Usage: setDefaultAppForExtensions ApplicationName.app ext1 [ext2 ...]"
        return 1
    fi

    local appName="$1"
    local appPath="/Applications/$appName"

    if [ ! -d "$appPath" ]; then
        echo "Error: Application $appName not found in /Applications."
        return 1
    fi

    local bundleID=$(mdls -name kMDItemCFBundleIdentifier -r "$appPath")

    if [ -z "$bundleID" ]; then
        echo "Error: Could not find bundle ID for $appPath"
        return 1
    fi

    shift # Remove the first argument, which is the application name

    if ! command -v duti &> /dev/null; then
        echo "'duti' is not installed. Attempting to install 'duti' using Homebrew..."
        if ! command -v brew &> /dev/null; then
            echo "Error: Homebrew is not installed. Please install Homebrew and retry."
            return 1
        fi
        brew install duti
    fi

    for ext in "$@"; do
        if duti -s "$bundleID" .$ext all; then
            echo "Set default app for .$ext to $appName successfully."
        else
            echo "Failed to set default app for .$ext to $appName"
        fi
    done
}
