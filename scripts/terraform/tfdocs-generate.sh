#!/bin/bash

set -o pipefail

#
# README.md file of each analyzed terraform module.
# Copyright 2022 alextorresruiz

function generate_aws_libs() {
  title "Generating Terraform Docs recursively"
  pwd

  pushd "$TF_MODULES_AWS_LIB_DIR" || exit

  local excluded_dirs_that_starts_with
  excluded_dirs_that_starts_with=(
    "."
    ".terraform"
    "examples"
  )

  local tf_dirs
  tf_dirs=$(find . -type f -name "*.tf" -exec dirname {} \; | sort -u)
  for tf_dir in $tf_dirs; do
    tf_dir="${tf_dir}"
    echo "tf_dir: $tf_dir"
  done

  for tf_dir in $tf_dirs; do
    info "Generating documentation for module: $tf_dir"

    if [[ -f "$tf_dir/$TF_DOCS_CONFIG_FILE" ]]; then
      info "Found $TF_DOCS_CONFIG_FILE in $tf_dir"

      if [[ -f "$tf_dir/README.md" ]]; then
        info "Found README.md in $tf_dir"
        info "Running terraform-docs $tf_dir"

        ushd "$tf_dir" || exit
        terraform-docs .
        popd || exit

      elif [[ -f "$tf_dir/readme.md" ]]; then
        info "Found readme.md in $tf_dir"
        info "Running terraform-docs $tf_dir"

        pushd "$tf_dir" || exit
        terraform-docs .
        popd || exit

      else
        warn "No README.md or readme.md found in $tf_dir"
      fi
    else
      warn "No $TF_DOCS_CONFIG_FILE found in $tf_dir"
    fi
  done

  popd || exit
}

function main() {
    generate_aws_libs
}

declare TF_DOCS_CONFIG_FILE=".terraform-docs.yml"
declare TF_MODULES_AWS_LIB_DIR="infrastructure/terraform/aws/libs"

source scripts/utils/printer.sh


main "$@"
