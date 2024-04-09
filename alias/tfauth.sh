#!/bin/bash

tfauth() {
  local force_mode=false
  local token="${GITLAB_PRIVATE_TOKEN:-$GITLAB_TOKEN}"
  local tfrc_file="$HOME/.terraformrc"

  # Parse the --force flag
  [[ "$1" == "--force" ]] && force_mode=true

  # Check for the GITLAB_PRIVATE_TOKEN or GITLAB_TOKEN
  if [[ -z "$token" ]]; then
    echo "❌ No GitLab token found. Please set GITLAB_PRIVATE_TOKEN or GITLAB_TOKEN."
    return 1
  fi

  # Check if the .terraformrc file already exists
  if [[ -f "$tfrc_file" && "$force_mode" == false ]]; then
    echo "⚠️ The .terraformrc file already exists. Use --force to override."
    return 1
  fi

  # Write the .terraformrc file
  echo "Writing credentials to $tfrc_file..."
  echo "credentials \"gitlab.com\" {" > "$tfrc_file"
  echo "  token = \"$token\"" >> "$tfrc_file"
  echo "}" >> "$tfrc_file"

  # Success message
  echo "✅ .terraformrc has been successfully created/updated at $tfrc_file"
}

# Create an alias for the tfauth function
alias tfauth='tfauth'
