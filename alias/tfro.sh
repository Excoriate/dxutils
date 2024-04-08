#!/bin/bash

# tfro function to intelligently initialize and plan Terraform configurations in the current directory or recursively based on flags.
# Adds informative UI messages for a better user experience.

tfro() {
  local all_vars_mode=false
  local brave_mode=false
  local var_file=""
  local current_dir=$(pwd)

  # Ensure Terraform commands find the proper binary managed by tfswitch.
  export PATH="$HOME/bin:$PATH"

  echo "🔎 Checking for Terraform installation..."
  if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install it to continue."
    return 1
  else
    echo "🚀 Terraform version: $(terraform version)"
  fi

  # Parse flags and arguments
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --all-vars)
        all_vars_mode=true
        ;;
      --brave)
        brave_mode=true
        ;;
      *)
        if [[ -f "$1" ]]; then
          var_file="$1"
        fi
        ;;
    esac
    shift
  done

  # Clean .terraform directory if --brave is specified
  if [[ "$brave_mode" == true && -d ".terraform" ]]; then
    echo "🧹 Cleaning up previous Terraform state in $current_dir..."
    rm -rf ".terraform"
  fi

  # Function to find and set var-file if not explicitly passed
  find_var_file() {
    if [[ -z "$var_file" ]]; then
      if [[ -f "fixtures/fixtures.tfvars" ]]; then
        var_file="fixtures/fixtures.tfvars"
        echo "📁 Found var-file in fixtures/"
      elif [[ -f "config/fixtures.tfvars" ]]; then
        var_file="config/fixtures.tfvars"
        echo "📁 Found var-file in config/"
      else
        echo "ℹ️ No var-file found in fixtures/ or config/, proceeding without it."
      fi
    else
      echo "📄 Using provided var-file: $var_file"
    fi
  }

  find_var_file

  # Initialize Terraform
  echo "⚙️ Initializing Terraform in $current_dir..."
  terraform init && echo "✅ Initialization successful."

  # Planning Terraform with or without var-file
  echo "🗺 Planning Terraform..."
  if [[ -n "$var_file" ]]; then
    echo "Using var-file: $var_file"
    terraform plan -var-file="$var_file" && echo "✅ Plan successful."
  else
    terraform plan && echo "✅ Plan successful."
  fi
}

# To use, simply call tfro [--all-vars] [--brave] [var-file]
