#!/bin/bash
#
# Generate .env files with a built-in configuration ready to be used for TerraGrunt/Terraform purposes.
# Copyright 2022 alextorresruiz

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

  gum confirm "Confirm .env file (.env.$env_input.terraform)?" && confirm_env_to_create "${env_input}"
}

function confirm_env_to_create(){
  local env_selected
  env_selected=$1

  env_name="${env_selected}"
  dot_env_file_name=".env.${env_name}.terraform"

  gum style --foreground 212 "Creating environment for Terraform: $env_name"
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

function generate_terraform_config_data(){
  local tf_state_bucket
  local tf_state_region
  local tf_state_lock_table

  # Specific Terraform configuration.
  tf_state_region="eu-central-1"
  tf_state_bucket="platform-tfstate-account-${env_name}"
  tf_state_lock_table="platform-tfstate-account-${env_name}"

  local type
  local domain
  local environment
  local region
  local service
  local component

  environment="${env_name}"
  # Set  type.
  gum style --foreground 212 " type: "
  type=$(gum choose "infrastructure" "automation" "service" "application" "storage" "database")

  type=$(echo "$type" | tr -d '[:space:]')
  local valid_types=("infrastructure" "automation" "service" "application" "storage" "database")

  if [[ ! " ${valid_types[@]} " =~ " ${type} " ]]; then
    gum style --foreground 196 "The  type must be one of the following: infrastructure, automation, service, application, storage or database."
    exit 1
  fi

  # Set  domain.
  if [[ "$type" == "infrastructure" ]]; then
    gum style --foreground 212 "The 'type' entered is infrastructure, so select valid domains based on this type"
    domain=$(gum choose "foundational" "configuration" "platform")
  else
    gum style --foreground 212 "The 'type' entered is not infrastructure, so select valid domains based on this type"
    domain=$(gum input --placeholder "Enter the  domain. E.g.: domain=authentication")
  fi

  # Set the  region
  gum style --foreground 212 "Select the  region: "
  region=$(gum choose "eu-central-1" "eu-west-1" "eu-west-2" "eu-west-3" "eu-north-1" "eu-south-1" "us-east-1" "us-east-2" "us-west-1" "us-west-2" "ap-east-1" "ap-south-1" "ap-northeast-1" "ap-northeast-2" "ap-northeast-3" "ap-southeast-1", "ap-southeast-2" "ca-central-1" "cn-north-1" "cn-northwest-1" "me-south-1" "sa-east-1")

  if [[ -z "$region" ]]; then
    gum style --foreground 196 "The  region cannot be empty."
    exit 1
  fi

  if [[ "$region" != "eu-central-1" && "$region" != "eu-west-1" && "$region" != "eu-west-2" && "$region" != "eu-west-3" && "$region" != "eu-north-1" && "$region" != "eu-south-1" && "$region" != "us-east-1" && "$region" != "us-east-2" && "$region" != "us-west-1" && "$region" != "us-west-2" && "$region" != "ap-east-1" && "$region" != "ap-south-1" && "$region" != "ap-northeast-1" && "$region" != "ap-northeast-2" && "$region" != "ap-northeast-3" && "$region" != "ap-southeast-1" && "$region" != "ap-southeast-2" && "$region" != "ca-central-1" && "$region" != "cn-north-1" && "$region" != "cn-northwest-1" && "$region" != "me-south-1" && "$region" != "sa-east-1" ]]; then
    gum style --foreground 196 "The  region must be one of the following: eu-central-1, eu-west-1, eu-west-2, eu-west-3, eu-north-1, eu-south-1, us-east-1, us-east-2, us-west-1, us-west-2, ap-east-1, ap-south-1, ap-northeast-1, ap-northeast-2, ap-northeast-3, ap-southeast-1, ap-southeast-2, ca-central-1, cn-north-1, cn-northwest-1, me-south-1, sa-east-1."
    exit 1
  fi

  # Set  service.
  if [[ "$type" == "infrastructure" ]]; then
    gum style --foreground 212 "The 'type' entered is infrastructure, so select valid services based on this type"
    service=$(gum choose "network" "compute" "account" "containers" "storage" "database" "security" "monitoring" "logging" "notification" "authentication" "audit" "orchestration" "analytics" "messaging" "traffic")
  else
    gum style --foreground 212 "The 'type' entered is not infrastructure, so select valid services based on this type"
    service=$(gum input --placeholder "Enter the  service. E.g.: service=signin-service")
  fi

  # Set  component.
  if [[ "$type" == "infrastructure" ]]; then
    gum style --foreground 212 "The 'type' entered is infrastructure, so the component should normally refer to a module."
  fi

  component=$(gum input --placeholder "Enter the  component. E.g.: component=rest-api")

  local export_keyword
  gum confirm "Do you want to include the 'export' keyword in the $dot_env_file_name file?" && export_keyword="export " || export_keyword=""

  echo "${export_keyword}TYPE=$type" >> "$dot_env_file_name"
  echo "${export_keyword}ENVIRONMENT=$environment" >> "$dot_env_file_name"
  echo "${export_keyword}REGION=$region" >> "$dot_env_file_name"
  echo "${export_keyword}DOMAIN=$domain" >> "$dot_env_file_name"
  echo "${export_keyword}SERVICE=$service" >> "$dot_env_file_name"
  echo "${export_keyword}COMPONENT=$component" >> "$dot_env_file_name"

  gum confirm "Do you want to preview the .env file" && gum pager < "$dot_env_file_name"
  gum style --foreground 46 "The .env file has been created ✅"
}

function main() {
  gum style \
	--foreground 212 --border-foreground 212 --border double \
	--align center --width 50 --margin "1 2" --padding "2 4" \
	'Terraform .env (DotEnv) File Generator'

  # 1. Pick, and confirm the environment to configure.
	choose_env_to_configure

  # 2. Check whether we are in a .git repo, and in the root dir. Otherwise, fail with an error.
  is_git_repo

  # 3. Generate dotEnv file, but empty.
  create_or_replace_dot_env_file

  # 4. Fill the required terraform variables.
  generate_terraform_config_data
}

declare env_name
declare dot_env_file_name

main "$@"
