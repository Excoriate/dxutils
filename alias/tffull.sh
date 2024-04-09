#!/bin/bash

# tffull function to intelligently initialize, plan, apply, and destroy Terraform configurations in the current directory.
# It uses smart logic for handling variable files and adds informative UI messages for a better user experience.

tffull() {
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

  # Parse arguments for a var-file, if provided.
  if [[ -f "$1" ]]; then
    var_file="$1"
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
    terraform plan -var-file="$var_file" && echo "✅ Plan successful."
  else
    terraform plan && echo "✅ Plan successful."
  fi

  # Applying Terraform with auto-approve
  echo "🚀 Applying Terraform..."
  if [[ -n "$var_file" ]]; then
    terraform apply -var-file="$var_file" -auto-approve && echo "✅ Apply successful."
  else
    terraform apply -auto-approve && echo "✅ Apply successful."
  fi

  # Destroying Terraform resources with auto-approve
  echo "💥 Destroying Terraform resources..."
  if [[ -n "$var_file" ]]; then
    terraform destroy -var-file="$var_file" -auto-approve && echo "✅ Destroy successful."
  else
    terraform destroy -auto-approve && echo "✅ Destroy successful."
  fi
}

# To use, simply call tffull [var-file]
