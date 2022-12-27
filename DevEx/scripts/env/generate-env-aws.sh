#!/bin/bash
#
# Set AWS credentials based on pre-configured AWS profiles.
# Copyright 2022 alextorresruiz

function discover_aws_profiles_from_aws_creds {
  local aws_profiles

  aws_profiles=($(grep -o '\[.*\]' ~/.aws/credentials | sed 's/\[//g' | sed 's/\]//g'))

  if [[ "${#aws_profiles[@]}" -eq 0 ]]; then
    gum style --foreground 196 --background 232 "No AWS profiles found in ~/.aws/credentials"
    exit 1
  else
    profile=$(gum choose "${aws_profiles[@]}")
    echo ""
    gum style --foreground 212 "Selected AWS profile [$profile] successfully."
  fi
}

function write_aws_credentials() {
  if [ ! -f "$dot_env_file_name" ]; then
    gum style --foreground 196 "The file $dot_env_file_name does not exist."
    exit 1
  fi

  # Ask the user if they want the export keyword to be included
  local export_keyword
  gum confirm "Do you want to include the 'export' keyword in the .env file?" && export_keyword="export " || export_keyword=""

  # If the aws configure get "$profile".aws_session_token is empty or not set in the profile, ignore it, otherwise, also export it
  if [[ -n "$(aws configure get "$profile".aws_session_token --profile "$profile")" ]]; then
    local aws_session_token
    aws_session_token=$(aws configure get "$profile".aws_session_token --profile "$profile")
    echo "${export_keyword}AWS_SESSION_TOKEN=$aws_session_token" >> "$dot_env_file_name"
  fi

  if [[ -n "$(aws configure get "$profile".aws_security_token --profile "$profile")" ]]; then
    local aws_security_token
    aws_security_token=$(aws configure get "$profile".aws_security_token --profile "$profile")
    echo "${export_keyword}AWS_SECURITY_TOKEN=$aws_security_token" >> "$dot_env_file_name"
  fi

  local aws_access_key_id
  aws_access_key_id=$(aws configure get "$profile".aws_access_key_id --profile "$profile")

  local aws_secret_access_key
  aws_secret_access_key=$(aws configure get "$profile".aws_secret_access_key --profile "$profile")

  echo "${export_keyword}AWS_ACCESS_KEY_ID=$aws_access_key_id" >> "$dot_env_file_name"
  echo "${export_keyword}AWS_SECRET_ACCESS_KEY=$aws_secret_access_key" >> "$dot_env_file_name"
}

function export_aws_creds_per_profile(){
  local profile
  profile=$1

  if [[ -n "${AWS_ACCESS_KEY_ID}" ]]; then
    unset AWS_ACCESS_KEY_ID
  fi

  if [[ -n "${AWS_SECRET_ACCESS_KEY}" ]]; then
    unset AWS_SECRET_ACCESS_KEY
  fi

  if [[ -n "${AWS_SESSION_TOKEN}" ]]; then
    unset AWS_SESSION_TOKEN
  fi

  if [[ -n "${AWS_DEFAULT_REGION}" ]]; then
    unset AWS_DEFAULT_REGION
  fi

  # If the aws configure get "$profile".aws_session_token is empty or not set in the profile, ignore it, otherwise, also export it
  if [[ -n "$(aws configure get "$profile".aws_session_token --profile "$profile")" ]]; then
    local aws_session_token
    aws_session_token=$(aws configure get aws_session_token --profile "$profile")
    export AWS_SESSION_TOKEN="$aws_session_token"
  fi

  if [[ -n "$(aws configure get "$profile".aws_security_token --profile "$profile")" ]]; then
    local aws_security_token
    aws_security_token=$(aws configure get aws_security_token --profile "$profile")
    export AWS_SECURITY_TOKEN="$aws_security_token"
  fi

  local aws_access_key_id
  local aws_secret_access_key

  aws_access_key_id=$(aws configure get aws_access_key_id --profile "$profile")
  aws_secret_access_key=$(aws configure get aws_secret_access_key --profile "$profile")

  export AWS_ACCESS_KEY_ID="$aws_access_key_id"
  export AWS_SECRET_ACCESS_KEY="$aws_secret_access_key"

  echo
  gum style --foreground 212 "All Set!!"
}

function is_git_repo() {
  if [ -d .git ] || [ -d ../.git ] || [ -d ../../git ]; then
    gum style --foreground 212 "This is a git repo..., nice! s"
  else
    gum style --foreground 196 "This is not a git repo, please run this command from the root of a git repo."
    exit 1
  fi
}

function choose_env_to_configure(){
  local env_input
  gum style --foreground 212 "Choose the environment to configure: "

  env_input=$(gum choose "sandbox" "int" "prod" "stage" "master")

  if [[ -z "$env_input" ]]; then
    gum style --foreground 196 "The environment cannot be empty."
    exit 1
  fi

  if [[ "$env_input" != "sandbox" && "$env_input" != "dev" && "$env_input" != "int" && "$env_input" != "stage" && "$env_input" != "prod" && "$env_input" != "master" ]]; then
    gum style --foreground 196 "The environment must be one of the following: sandbox, dev, int, stage, prod or master."
    exit 1
  fi

  gum confirm "Confirm .env file (.env.$env_input.aws)?" && confirm_env_to_create "${env_input}"
}

function confirm_env_to_create(){
  local env_selected
  env_selected=$1

  env_name="${env_selected}"
  dot_env_file_name=".env.${env_name}.aws"

  gum style --foreground 212 "Creating environment: $env_name"
  gum style --foreground 212 "AWS credentials will be written to the file: $dot_env_file_name"
}

function create_or_replace_dot_env_file(){
  if [ -f "$dot_env_file_name" ]; then
    gum style --foreground 196 "The file $dot_env_file_name already exists."
    gum confirm "Do you want to replace it?" && rm -f "$dot_env_file_name" && touch "$dot_env_file_name"
  else
    touch "$dot_env_file_name"
  fi

  gum style --foreground 212 "The file $dot_env_file_name was created successfully in path $(pwd)"

  if [ -f .gitignore ]; then
    if ! grep -q "$dot_env_file_name" .gitignore; then
      echo "# Automatically generated. Do not modify. Check DevDex/scripts/aws/set-aws-creds.sh for more details..." >> .gitignore
      echo "$dot_env_file_name" >> .gitignore
      gum style --foreground 212 "Added .env named $dot_env_file_name to .gitignore file"
    fi
  fi

  gum style --foreground 212 "The file $dot_env_file_name was created successfully in path $(pwd)"
}

function main() {
  gum style \
	--foreground 212 --border-foreground 212 --border double \
	--align center --width 50 --margin "1 2" --padding "2 4" \
	'AWS .env (DotEnv) File Generator'

  # 1. Pick, and confirm the environment to configure.
	choose_env_to_configure

	# 2. List profiles stores and already configured in the ~/.aws/credentials file.
  discover_aws_profiles_from_aws_creds

  # 3. Create the files (.env)
  is_git_repo

  # 4. Create the file, initially empty.
  create_or_replace_dot_env_file

  # 5. Write the AWS credentials to the file.
  write_aws_credentials

  # 6. Export the AWS credentials for the given profile
  export_aws_creds_per_profile "$profile"
}

declare env_name
declare dot_env_file_name
declare profile

main "$@"
