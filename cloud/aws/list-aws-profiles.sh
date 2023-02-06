#!/bin/bash
#
# Set AWS credentials based on pre-configured AWS profiles.
# Copyright 2022 alextorresruiz

function list_aws_profiles() {
  local profiles
  profiles=($(aws configure list-profiles))

  if [[ "${#profiles[@]}" -eq 0 ]]; then
    gum style --foreground 196 --background 232 "No AWS profiles found in ~/.aws/credentials"
    exit 1
  else
    local profile
    profile=$(gum choose "${profiles[@]}")
    echo ""
    gum style --foreground 212 "Selected AWS profile [$profile] successfully."
  fi

  # Check first if there was a profile exported, if so, clean it up
  if [[ -n "$AWS_PROFILE" ]]; then
    gum style --foreground 212 "Cleaning up AWS profile [$AWS_PROFILE]..."
    unset AWS_PROFILE
  fi

  if [[ $profile == *"wbd-"* ]] || [[ $profile == *"discovery-aws"* ]]; then
    gum style --foreground 212 "Using AWS SSO to login..."
    export AWS_PROFILE=$profile
    local is_logged_in
    is_logged_in=$(aws sso login --profile "$profile")

    if [[ ${?} -ne 0 ]]; then
      gum style --foreground 196 --background 232 "Error logging in to AWS SSO. Please check your credentials."
      exit 1
    fi

    local role
    role=$(echo "$profile" | cut -d'.' -f2)

    gum style --foreground 212 "Getting AWS SSO credentials for role [$role]..."
    aws configure get sso_account_id --profile "$profile"
    aws configure get sso_region --profile "$profile"
    aws configure get sso_role_name --profile "$profile"

    eval "$(aws2-wrap --profile "$profile" --export)"

    gum style --foreground 212 "Exported AWS profile with SSO: [$profile]"
  else
    gum style --foreground 212 "Exported AWS profile without SSO: [$profile]"
    export AWS_SECRET_ACCESS_KEY=$(aws configure get "$profile".aws_secret_access_key)
    export AWS_ACCESS_KEY_ID=$(aws configure get "$profile".aws_access_key_id)
    export AWS_SECURITY_TOKEN=$(aws configure get "$profile".aws_session_token)
    export AWS_SESSION_TOKEN=$(aws configure get "$profile".aws_session_token)
    export AWS_PROFILE=$profile
  fi
}


function main() {
  gum style \
	--foreground 212 --border-foreground 212 --border double \
	--align center --width 50 --margin "1 2" --padding "2 4" \
	'AWS Profile Selector'

  #1. List AWS profiles.
  list_aws_profiles "$1"
}

main "$@"
