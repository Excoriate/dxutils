#!/bin/bash

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

    # Remove the first argument, which is the application name
    shift

    # Install 'duti' if not present
    if ! command -v duti &> /dev/null; then
        echo "'duti' is not installed. Attempting to install 'duti' using Homebrew..."
        if ! command -v brew &> /dev/null; then
            echo "Error: Homebrew is not installed. Please install Homebrew and retry."
            return 1
        fi
        brew install duti
    fi

    # Loop through the rest of the arguments, which are file extensions
    for ext in "$@"; do
        if duti -s "$bundleID" .$ext all; then
            echo "Set default app for .$ext to $appName successfully."
        else
            echo "Failed to set default app for .$ext to $appName"
        fi
    done
}
