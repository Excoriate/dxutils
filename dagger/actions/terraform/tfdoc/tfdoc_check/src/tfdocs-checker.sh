#!/bin/bash

#
# Check whether a given module has a .terraform-docs.yml configuration file.
# Copyright 2022 alextorresruiz

set -o pipefail


#######################################
# Review all the modules, and identify them under a given directory.
# Globals:
#   WORKING_DIR
# Arguments:
#   None
#######################################
function analyze_modules() {
  title "Validating terraform doc configuration"

  pushd "$WORKING_DIR" >/dev/null || {
    fatal "Directory $WORKING_DIR does not exist in path $PWD"
  }

  local tf_dirs
  tf_dirs=$(find . -type f -name "*.tf" -exec dirname {} \; | sort -u)

  local tf_dirs_filtered
  tf_dirs_filtered=$(echo "$tf_dirs" | grep -v -E 'example|examples|test')
  if [[ "$tf_dirs_filtered" == "true" ]]; then
    tf_dirs_filtered=$(echo "$tf_dirs_filtered" | grep -v -E 'example|examples|test')
  fi

  for dir in $tf_dirs_filtered; do
    # only call run_checks if dir is not an empty string, and it is a valid directory
    if [[ -n "$dir" ]] && [[ -d "$dir" ]]; then
      info "Discovered module: $dir"
      run_checks "$dir"
    fi
  done

  popd || exit
}

function run_checks(){
  local tf_dir
  tf_dir=$1

  info "Running checks for module $tf_dir"

  local tf_docs_config_file
  tf_docs_config_file="$tf_dir/.terraform-docs.yml"

  if [[ -f "$tf_docs_config_file" ]]; then
    if [[ ! -s "$tf_docs_config_file" ]]; then
      err "Found empty .terraform-docs.yml configuration file in $tf_dir"
      OUT_ERRORS=$((OUT_ERRORS + 1))
    fi
  else
    err "Missing .terraform-docs.yml configuration file in $tf_dir"
      OUT_ERRORS=$((OUT_ERRORS + 1))

  fi

  #Check whether a README.md or readme.md is present in the module directory
  local readme_file
  readme_file="$tf_dir/README.md"
  if [[ ! -f "$readme_file" ]]; then
    readme_file="$tf_dir/readme.md"
    if [[ ! -f "$readme_file" ]]; then
      err "Missing README.md or readme.md file in $tf_dir"
      OUT_ERRORS=$((OUT_ERRORS + 1))
    fi
  fi

  info "Check completed for module: $tf_dir"
}

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

    analyze_modules

    result
}


#######################################
# Ensures that the scripts/ and its shell/bash
# utilities are properly sourced.
######################################
# shellcheck disable=SC1090
#declare SCRIPTS_DIR
#declare SCRIPTS_TF_DIR
#declare SCRIPTS_UTILS_DIR
#SCRIPTS_DIR="scripts"
#SCRIPTS_TF_DIR="$SCRIPTS_DIR/terraform"
#SCRIPTS_UTILS_DIR="$SCRIPTS_DIR/utils"
#
#
#if [[ ! -d "$SCRIPTS_DIR" ]]; then
#  echo "Scripts directory not found, but it's required. Current path is $PWD"
#  echo
#  exit 1
#else
#  echo "Found scripts directory: $SCRIPTS_DIR"
#
#  for file in "$SCRIPTS_TF_DIR"/*.sh; do
#    # shellcheck disable=SC1090
#    source "$file"
#  done
#
#  for file in "$SCRIPTS_UTILS_DIR"/*.sh; do
#    # shellcheck disable=SC1090
#    source "$file"
#  done
#fi

source fs.sh
source printer.sh

declare WORKING_DIR
declare OUT_ERRORS=0


main "$@"
