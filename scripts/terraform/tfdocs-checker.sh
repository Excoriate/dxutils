#!/bin/bash

set -o pipefail

#
# Check whether a given module has a .terraform-docs.yml configuration file.
# Copyright 2022 alextorresruiz

function browse_modules() {
  title "Validating terraform doc configuration"

  pushd "$TF_WORKING_DIR" || exit

  local excluded_dirs_that_starts_with
  excluded_dirs_that_starts_with=(
    "examples"
  )

  local tf_dirs
  tf_dirs=$(find . -type f -name "*.tf" -exec dirname {} \; | sort -u)

  for tf_dir in $tf_dirs; do
    # if the directory name, or path, contains any of the values in the excluded_dirs_that_starts_with array, skip it.
    for excluded_dir in "${excluded_dirs_that_starts_with[@]}"; do
      if [[ "$tf_dir" == *"$excluded_dir"* ]]; then
        warn "Skipping $tf_dir"
        continue 2
      else
        info "Checking $tf_dir ..."
        analyze_tf_module "$tf_dir"
      fi
    done

  done

  popd || exit
}

function analyze_tf_module(){
  local tf_dir
  tf_dir="$1"

  local files_to_look_for
  files_to_look_for=(
    "readme.md"
    "$TF_DOCS_CONFIG_FILE"
  )

  # get the size of the array files_to_look_for
  local files_count
  files_count=2

  # Check if the tf_dir directory has all the files stored in the files_to_look_for array. If any is missing, exit with 1.
  for file in "${files_to_look_for[@]}"; do
    if [[ -f "$tf_dir/$file" ]]; then
      info "Found $file in $tf_dir"
      files_count=$((files_count - 1))
    else
      warn "A missing (required) file was identified. File $file in $tf_dir"
    fi
  done

  if [[ $files_count -eq 0 ]]; then
      summary "Result for module: $tf_dir [OK]"
      info "Errors/missing files: $files_count"
  else
    err "Missing files in $tf_dir"
    ls -ltrah "$tf_dir"
    exit 1
  fi
}

function parse_args() {
  for arg in "$@"; do
    echo "argument received --> [$arg]"
    echo
  done

  for i in "$@"; do
    case $i in
    -d=* | --dir=*)
      TF_WORKING_DIR="${i#*=}"
      shift
      ;;
    *) err "Unknown option: '-${i}'" "See '${0} --help' for usage" ;;
    esac
  done
}


function main() {
    parse_args "$@"
    browse_modules
}

declare TF_DOCS_CONFIG_FILE=".terraform-docs.yml"
declare TF_WORKING_DIR

source ../../utils/printer.shmain "$@"
