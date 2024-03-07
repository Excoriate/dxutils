#!/bin/bash
# Define the function
awsvarenv() {
  # Check for AWS-related environment variables and store them
  local aws_vars=$(env | grep '^AWS_' || true)

  # Check if any AWS-related environment variables were found
  if [ -z "$aws_vars" ]; then
    echo "No AWS environment variables are exported."
  else
    echo "Exported AWS environment variables:"
    echo "$aws_vars"

    # Attempt to copy the variables to the clipboard
    # pbcopy for macOS, xclip or xsel for Linux, clip.exe for WSL
    if command -v pbcopy > /dev/null 2>&1; then
      echo "$aws_vars" | pbcopy
    elif command -v xclip > /dev/null 2>&1; then
      echo "$aws_vars" | xclip -selection clipboard
    elif command -v xsel > /dev/null 2>&1; then
      echo "$aws_vars" | xsel --clipboard --input
    elif command -v clip.exe > /dev/null 2>&1; then # For WSL
      echo "$aws_vars" | clip.exe
    else
      echo "Clipboard utility not found. Please manually copy the above variables."
      return 1
    fi

    echo "AWS environment variables copied to clipboard."
  fi
}

# Alias definition for both bash and zsh
alias awsenv='awsvarenv'
