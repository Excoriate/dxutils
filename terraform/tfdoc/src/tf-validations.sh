#!/bin/bash

set -o pipefail

#
# Run the entire lifecycle, for Terraform, until plan.
# Copyright 2022 alextorresruiz



#######################################
# Check whether the given directory includes the .terraform-docs.yml
# configuration file.
# Globals:
#   WORKING_DIR: Directory where the module lives
# Arguments:
#   dir: Directory where the module lives.
function parse_args() {
  for arg in "$@"; do
    echo "argument received --> [$arg]"
    echo
  done

  for i in "$@"; do
    case $i in
    -d=* | --dir=*)
      WORKING_DIR="${i#*=}"
      check_if_directory_exists "$WORKING_DIR"
      shift
      ;;
    *) err "Unknown option: '-${i}'" "See '${0} --help' for usage" ;;
    esac
  done
}

function result() {
  summary "Number of errors: $OUT_ERRORS"
  if [[ $OUT_ERRORS -gt 0 ]]; then
    exit 1
  fi
}


function main() {
    OUT_ERRORS=0

    parse_args "$@"

    result
}


# shellcheck disable=SC1090
if [[ ! -d "./utils" ]]; then
  echo "utils directory not found, but it's required. Current path is $PWD"
  echo "Current files are: "
  ls -ltrah
  echo
  exit 1
else
  for file in "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"/utils/*.sh; do
    # shellcheck disable=SC1090
    echo "sourced file: $file"
    source "$file"
done
fi

declare WORKING_DIR
declare OUT_ERRORS=0
# Specific options for terraform.
declare TF_CONFIG_BACKEND
declare TF_CONFIG_VAR_FILE




main "$@"
