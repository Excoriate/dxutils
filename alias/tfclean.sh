#!/bin/bash

# tfClean for cleaning .terraform directories and optionally .terragrunt-cache directories on macOS

tfClean() {
  local terragrunt_mode=false
  local cleaned_dirs=()

  [[ "$1" == "--terragrunt" ]] && terragrunt_mode=true

  echo "🔍 Searching for directories to clean..."

  # Find and clean .terraform directories
  find . -type d -name ".terraform" -prune -maxdepth 5 -exec bash -c 'echo "🧹 Cleaning up {}..."; rm -rf "{}"' \;

  # If terragrunt mode is enabled, additionally find and clean .terragrunt-cache directories
  if $terragrunt_mode; then
    find . -type d -name ".terragrunt-cache" -prune -maxdepth 5 -exec bash -c 'echo "🧹 Cleaning up {}..."; rm -rf "{}"' \;
  fi

  # Report Summary
  # Note: Directories are cleaned immediately, so we don't track individual directories here.
  echo "📊 Clean-up Summary: Check the output above for details of cleaned directories."
}

# Usage: tfClean [--terragrunt]
