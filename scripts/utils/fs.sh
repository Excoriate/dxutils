#!/bin/bash
#
# Set of utils, for filesystem and OS stuffs
# Copyright 2022 alextorresruiz

#######################################
# Check whether the given directory exist.
# Globals:
# Arguments:
#   $1 - directory path
#######################################
function check_if_directory_exists() {
    if [ ! -d "$1" ]; then
        echo "Directory $1 does not exist"
        echo "Path from where this bash script is being executed: $PWD"
        exit 1
    fi
}

#######################################
# Check whether the given file, exist, and
# has content.
# Globals:
# Arguments:
#   $1 - file path
#######################################
function check_if_file_has_content() {
    if [ ! -s "$1" ]; then
        echo "File $1 does not exist or is empty"
        exit 1
    fi

    if [ ! -s "$1" ]; then
        echo "File $1 is empty"
        exit 1
    fi
}
