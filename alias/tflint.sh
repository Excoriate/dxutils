#!/bin/bash

# Enhanced TFLint script to lint Terraform modules. It searches directories up to 5 levels deep (default),
# checking for the presence of .tflint.hcl and .tf files, excluding and logging specified directories such as .git, .vscode, etc.
# It proceeds with linting if both conditions are met, differentiating between non-Terraform modules, Terraform modules
# without .tflint.hcl, and valid modules, providing clear messaging for each case. It continues linting all found modules,
# accumulating any lint errors for reporting at the end.

tflintgen() {
  if ! command -v tflint &> /dev/null; then
    echo "❌ TFLint is not installed. Please install it to continue."
    return 1
  fi

  local max_depth=5  # Default search depth is 5 levels
  local exclude_dirs=".idea .git .vscode .node_modules .terraform .terragrunt-cache"
  local exclude_patterns=(-name .idea -o -name .git -o -name .vscode -o -name .node_modules -o -name .terraform -o -name .terragrunt-cache)

  echo "🔍 Searching for Terraform modules up to $max_depth level(s) deep..."
  local lint_errors=()
  local ignored_directories=()

  # First, log excluded directories
  for exclude_dir in $exclude_dirs; do
    find . -type d -name "$exclude_dir" -maxdepth $max_depth -exec echo "⏭️ Ignoring $exclude_dir directory" \;
  done

  while IFS= read -r dir; do
    if [[ -z "$dir" ]]; then
      continue
    fi

    local has_tflint_file=$(find "$dir" -maxdepth 1 -name ".tflint.hcl")
    local has_terraform_files=$(find "$dir" -maxdepth 1 -name "*.tf")

    if [[ -n "$has_terraform_files" ]]; then
      if [[ -n "$has_tflint_file" ]]; then
        echo "\n📁 Linting Terraform module in $dir with specific .tflint.hcl..."
        if ! (cd "$dir" && tflint --config=.tflint.hcl); then
          lint_errors+=("$dir")
        fi
      else
        echo "\n⚠️ Valid Terraform module without .tflint.hcl found in $dir"
      fi
    else
      if [[ -n "$has_tflint_file" ]]; then
        ignored_directories+=("$dir")
        echo "\n⏭️ Ignored $dir (.tflint.hcl found but no Terraform files)"
      else
        echo "\n⏭️ $dir is not a Terraform module."
      fi
    fi
  done < <(find . -type d -maxdepth "$max_depth" \( "${exclude_patterns[@]}" \) -prune -false -o -type d -print)

  # Summary of lint errors
  if [ ${#lint_errors[@]} -ne 0 ]; then
    echo "❌ Linting issues found in the following directories:"
    for err in "${lint_errors[@]}"; do
      echo "  - $err"
    done
  fi

  # Summary of ignored directories
  if [ ${#ignored_directories[@]} -ne 0 ]; then
    echo "⏭️ The following directories were ignored because they did not meet the criteria:"
    for ignored in "${ignored_directories[@]}"; do
      echo "  - $ignored"
    done
  fi

  if [ ${#lint_errors[@]} -eq 0 ] && [ ${#ignored_directories[@]} -eq 0 ]; then
    echo "✅ No issues found."
  fi
}

# Alias definition for convenience.
alias tflintgen='tflintgen'
