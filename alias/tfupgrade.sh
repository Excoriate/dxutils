#!/bin/bash

# tfInitUpgrade for running 'terraform init -upgrade' on Terraform modules

tfInitUpgrade() {
  local init_dirs=()
  local failed_dirs=()

  echo "🔄 Running 'terraform init -upgrade' on Terraform modules..."

  find . -type f -name '*.tf' -not -path '*/\.*' -exec dirname "{}" \; | sort -u | while read -r dir; do
    if (cd "$dir" && terraform init -upgrade); then
      init_dirs+=("$dir")
      echo "✅ Successfully initialized $dir"
    else
      failed_dirs+=("$dir")
    fi
  done

  # Report Summary
  echo "📊 Initialization Summary:"
  if [ ${#init_dirs[@]} -gt 0 ]; then
    echo "Successfully initialized Terraform in the following directories:"
    for dir in "${init_dirs[@]}"; do
      echo "  - $dir"
    done
  fi

  if [ ${#failed_dirs[@]} -gt 0 ]; then
    echo "Failed to initialize Terraform in the following directories:"
    for dir in "${failed_dirs[@]}"; do
      echo "  - $dir"
    done
  else
    echo "All Terraform directories were successfully initialized! 🎉"
  fi
}

# To use, simply call tfInitUpgrade
