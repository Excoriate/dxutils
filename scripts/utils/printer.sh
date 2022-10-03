#!/bin/bash
#
# Set of common functions, shared across bash-scripts.
# Copyright 2022 alextorresruiz


function err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: ERROR: $*" >&2
}

function fatal() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: FATAL: $*" >&2
  exit 1
}

function warn(){
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: WARN: $*" >&2
}

function info(){
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: INFO: $*" >&2
}

function summary(){
  echo
  echo "====> SUMMARY: $*" >&2
  echo
  echo
}

function title(){
  echo "-----------------------------------------------------"
  echo " $*"
  echo "-----------------------------------------------------"
  echo
}
