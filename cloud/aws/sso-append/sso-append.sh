#!/bin/bash
set -eEu -o pipefail

if ! command -v aws &> /dev/null || ! command -v jq &> /dev/null ; then
    echo "AWS CLI or JQ is not installed. Please make sure both are installed."
    exit 1
fi

# Remove config_append if exists
config_append_file="$HOME/.aws/config_append"
config_file="$HOME/.aws/config"

if [[ -f "$config_append_file" ]]; then
  rm "$config_append_file"
fi

# Retrieve account infomration
at_filename=$(ls -t ~/.aws/sso/cache/*.json | grep -v botocore | head -n 1)
at=$(jq -r '.accessToken' < "$at_filename")
start_url=$(jq -r '.startUrl' < "$at_filename")
region=$(jq -r '.region' < "$at_filename")

# Iterate over account list
available_accounts=$(aws sso list-accounts --region "$region" --access-token "$at" --output json)
n_accounts=$(jq '.accountList | length' <<< "$available_accounts")
echo "Accounts found: $n_accounts"

# Loop through each account
IFS=$'\n' read -rd '' -a accounts <<< $(jq -r '.accountList | .[] | .accountId' <<< "$available_accounts")

# Function to process AWS accounts
process_account() {
  local account_id=$1
  local config_append_file=$2
  echo "Processing account: $account_id"

  # Retrieve role names for the account
  IFS=$'\n' read -rd '' -a roles <<< $(aws sso list-account-roles \
                                       --region "$region" \
                                       --access-token "$at" \
                                       --account-id "$account_id" \
                                       --query 'roleList[].roleName' \
                                       --output text)

  for role in "${roles[@]}"; do
    local config_profile_name="$account_id-$role"
    printf "\n[profile %s]\nsso_start_url = %s\nsso_region = %s\nsso_account_id = %s\nsso_role_name = %s\nsts_regional_endpoints = regional\nregion = %s\n" \
            "$config_profile_name" "$start_url" "$region" "$account_id" \
            "$role" "$region" >> "$config_append_file"
  done
}

for account in "${accounts[@]}"; do
  process_account "$account" "$config_append_file"
done

grep -Fvxf "$config_append_file" "$config_file" > temp && mv temp "$config_file"
cat "$config_append_file" >>  "$config_file"

echo "$config_append_file added to $config_file"
rm "$config_append_file"
