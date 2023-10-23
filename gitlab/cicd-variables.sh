#!/bin/bash
set -e

declare URL_PROJECT
declare ENCODED_PROJECT
declare PRIVATE_TOKEN

usage() {
    echo "Usage:"
    echo "  ./script.sh [--name variable_name --contains substring]"
    echo
    echo "Options:"
    echo "  --name       Only print the variable with this name."
    echo "  --contains   Print variables that contain this substring."
    exit 1
}

resolve_private_token(){
  if [ -z "$GITLAB_PRIVATE_TOKEN" ]; then
    echo "PRIVATE_TOKEN is not set. Please set it to your GitLab private token."
    exit 1
  fi

  PRIVATE_TOKEN=$GITLAB_PRIVATE_TOKEN
}

resolve_current_git_repo(){
  local git_origin
  git_origin=$(git config --get remote.origin.url)

  echo "Git origin: $git_origin"
  local project_url
  project_url=$(echo "$git_origin" | sed 's/.*://;s/\.git$//')

  if [ -z "$project_url" ]; then
    echo "Failed to resolve project URL. Please check your git origin."
    exit 1
  fi

  URL_PROJECT=$project_url
  ENCODED_PROJECT=$(echo "$URL_PROJECT" | sed 's/\//%2F/g')

  echo "Project URL: $project_url"
  echo "Encoded project URL: $ENCODED_PROJECT"
}

error_exit() {
    echo "${0}: ${1:-"Unknown Error"}" 1>&2
    exit 1
}

get_project_id() {
    echo "Fetching project id..."
    PROJECT_ID=$(curl --silent --show-error --fail --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" "https://gitlab.com/api/v4/projects/$ENCODED_PROJECT") || error_exit "Failed to fetch project id"
    PROJECT_ID=$(echo "$PROJECT_ID" | jq .id)

    [ -z "$PROJECT_ID" ] && error_exit "Failed to fetch the project id. Please check the project URL and your private token."
    echo "Project id found: $PROJECT_ID"
}

get_variables() {
    local project_id="$1"
    local name="${2:-}"
    local contains="${3:-}"

    curl --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" "https://gitlab.com/api/v4/projects/$project_id/variables" | \
    if [[ ! -z "$name" ]]; then
        # If a name is given, only print the matching variable
        jq ".[] | select(.key == \"$name\")"
    elif [[ ! -z "$contains" ]]; then
        # If a contains is given, print variables that contain this substring
        jq ".[] | select(.key | contains(\"$contains\"))"
    else
        # If no name is given, print all variables
        jq
    fi
}

while [ "$1" != "" ]; do
    case $1 in
        --name )      name="$2"
                      shift
                      ;;
        --contains )  contains="$2"
                      shift
                      ;;
        -h | --help ) usage
                      ;;
        * )           usage
                      ;;
    esac
    shift
done

resolve_private_token
resolve_current_git_repo
get_project_id
get_variables "$PROJECT_ID" "$name" "$contains"
