#!/bin/bash
#
# Set of interesting terraform utils.s
# Copyright 2022 alextorresruiz


#######################################
# Check whether a given directory is a valid terraform module, checking
# its expected files inside. E.g.: main.tf, variables.tf, outputs.tf, etc.
# Globals:
#   WORKING_DIR: Directory where the module lives.s
# Arguments:
#   dir: Directory where the module lives.s
# Returns:
#   0 if the directory is a valid terraform module, 1 otherwise.
#   1 if the directory
#######################################
function is_valid_terraform_module(){
  title "Checking whether the directory is a valid terraform module in dir: $1"

  local dir=${1:-$WORKING_DIR}
  local files=("main.tf" "variables.tf" "outputs.tf")
  local file
  for file in "${files[@]}"; do
    if [ ! -f "${dir}/${file}" ]; then
      err "File ${file} not found in ${dir}"
      exit 1
    fi
  done

  info "This module in directory ${dir} is valid"
}

#######################################
# Check whether the given directory includes the .terraform-docs.yml
# configuration file.
# Globals:
#   WORKING_DIR: Directory where the module lives
# Arguments:
#   dir: Directory where the module lives.
function is_tf_docs_config_exist(){
  local tf_dir=${1:-$WORKING_DIR}
  local tf_docs_config_file="$tf_dir/.terraform-docs.yml"

  if [[ -f "$tf_docs_config_file" ]]; then
    info ".terraform-docs.yml file already exists in $tf_dir"
  else
    err ".terraform-docs.yml file does not exist in $tf_dir"
  fi
}

#######################################
# Check whether the given module includes a backend configuration
# Check whether the given module includes a backend configuration
# Globals:
#   WORKING_DIR: Directory where the module lives
# Arguments:
#   dir: Directory where the module lives.
function check_if_backend_config_exists() {
  # Search for a file named backend.tf, if exist, make a cat. If not, fail with exit 1.
  local tf_dir=${1:-$WORKING_DIR}
  local backend_config_file="$tf_dir/backend.tf"

  if [[ -f "$backend_config_file" ]]; then
    info "backend.tf file already exists in $tf_dir"

    if grep -q "backend \"s3\"" "$backend_config_file"; then
      info "backend.tf file already includes a backend configuration for terraform, with S3"
      cat "$backend_config_file"
    else
      err "backend.tf file does not include a backend configuration for terraform, with S3"
      exit 1
    fi
  else
    err "backend.tf file does not exist in $tf_dir"
    exit 1
  fi
}

#######################################
# Clean the .terraform folder, if it's found in the module's directory.
# Globals:
#   WORKING_DIR: Directory where the module lives
# Arguments:
#   dir: Directory where the module lives.
function clean_dot_terraform_folder_if_exists() {
  local tf_dir=${1:-$WORKING_DIR}
  local dot_terraform_folder="$tf_dir/.terraform"

  if [[ -d "$dot_terraform_folder" ]]; then
    info "Removing .terraform folder in $tf_dir"
    rm -rf "$dot_terraform_folder"
  else
    info ".terraform folder does not exist in $tf_dir"
  fi
}


#######################################
# Check whether the .terraform-docs.yml file is empty.
# Globals:
#   WORKING_DIR: Directory where the module lives
# Arguments:
#   dir: Directory where the module lives.
function check_if_tf_docs_config_file_is_empty(){
  local tf_dir=${1:-$WORKING_DIR}
  local tf_docs_config_file="$tf_dir/.terraform-docs.yml"

  if [[ -s "$tf_docs_config_file" ]]; then
    info "Passed, .terraform-docs.yml file is not empty in $tf_dir"
  else
    err ".terraform-docs.yml file is empty in $tf_dir"
  fi
}

declare WORKING_DIR

