#!/usr/bin/env bash

# --------------------
#####################
# Terraform utils
#####################
tffull() {
  # Check if the var-file exists
  if [ ! -f "$1" ]; then
    echo "Error: Var-file $1 does not exist."
    return 1
  fi

  # Determine if auto-approve is enabled
  local auto_approve_flag="-auto-approve"
  if [ "$2" = "false" ]; then
    auto_approve_flag=""
  fi

  echo "Initializing Terraform..."
  terraform init && echo "Initialization successful." || return 1

  echo "Planning Terraform..."
  terraform plan -var-file="$1" && echo "Plan successful." || return 1

  echo "Applying Terraform..."
  terraform apply -var-file="$1" $auto_approve_flag && echo "Apply successful." || return 1

  if [ "$auto_approve_flag" = "-auto-approve" ]; then
    echo "Destroying Terraform resources with auto-approve..."
    terraform destroy -var-file="$1" -auto-approve && echo "Destroy successful." || return 1
  fi
}

# Define tfro directly for initializing and planning with handling var-file
tfro() {
  # Check if the var-file exists
  if [ ! -f "$1" ]; then
    echo "Error: Var-file $1 does not exist."
    return 1
  fi

  echo "Initializing Terraform..."
  terraform init && echo "Initialization successful." || return 1

  echo "Planning Terraform..."
  terraform plan -var-file="$1" && echo "Plan successful." || return 1
}

tfdocgen() {
  # Find directories containing .terraform-docs.yml up to 3 levels deep
  echo "Searching for .terraform-docs.yml files up to 3 levels deep..."
  local directories=$(find . -maxdepth 3 -type f -name ".terraform-docs.yml" -exec dirname {} \; | sort -u)

  if [ -z "$directories" ]; then
    echo "No .terraform-docs.yml files found."
    return 1
  fi

  # Loop through directories and generate Terraform docs
  for dir in $directories; do
    echo "Found .terraform-docs.yml in $dir"

    # Attempt to generate Terraform docs
    echo "Generating Terraform docs in $dir..."
    (cd "$dir" && terraform-docs markdown -c .terraform-docs.yml . --output-file=README.md)

    if [ $? -eq 0 ]; then
      echo "Terraform docs generated successfully in $dir"
    else
      echo "Error generating Terraform docs in $dir"
    fi
  done
}
