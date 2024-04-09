#!/bin/bash

# tfci function for Terraform Continuous Integration tasks with enhanced reporting.
# Reports on all Terraform modules analyzed, including success and failure summaries.

tfci() {
  local auto_mode=false
  local success_modules=()
  local failed_modules=()
  export PATH="$HOME/bin:$PATH"

  echo "🔍 Checking Terraform installation..."
  if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install it to continue."
    return 1
  else
    echo "🚀 Terraform version: $(terraform version)"
  fi

  [[ "$1" == "--auto" ]] && auto_mode=true

  process_directory() {
    local dir=$1
    if compgen -G "$dir/*.tf" > /dev/null; then
      echo "📁 Identified Terraform module in $dir."
      if [[ -d "$dir/.terraform" ]]; then
        echo "⚠️ Warning: .terraform directory found in $dir. Previous initialization detected."
      fi
      if (cd "$dir" && terraform init && terraform validate && terraform fmt -check); then
        echo "✅ All checks passed for $dir."
        success_modules+=("$dir")
        # Optional TFLint check
        if [[ -f "$dir/.tflint.hcl" ]]; then
          if command -v tflint &> /dev/null; then
            (cd "$dir" && tflint) && echo "✅ TFLint successful for $dir." || failed_modules+=("$dir (TFLint)")
          else
            echo "⚠️ TFLint is not installed. Skipping TFLint checks for $dir."
          fi
        fi
      else
        failed_modules+=("$dir")
      fi
    else
      echo "ℹ️ No Terraform files found in $dir. Skipping..."
    fi
  }

  if [[ "$auto_mode" == true ]]; then
    echo "🔃 Running in automatic mode. Inspecting directories up to 4 levels deep..."
    find . -type f -name '*.tf' -not -path '*/\.*' -exec dirname "{}" \; | sort -u | while read -r dir; do
      process_directory "$dir"
    done
  else
    if compgen -G "*.tf" > /dev/null; then
      process_directory "$(pwd)"
    else
      echo "ℹ️ The current directory does not contain Terraform files. Skipping..."
    fi
  fi

  # Report Summary
  echo "📊 Process Summary:"
  if [ ${#success_modules[@]} -gt 0 ]; then
    echo "✅ Successful Modules:"
    for mod in "${success_modules[@]}"; do
      echo "  - $mod"
    done
  fi

  if [ ${#failed_modules[@]} -gt 0 ]; then
    echo "❌ Failed Modules:"
    for mod in "${failed_modules[@]}"; do
      echo "  - $mod"
    done
  else
    echo "No failures detected! 🎉"
  fi
}

# To use, call tfci [--auto]
