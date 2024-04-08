#!/bin/bash

tfdocgen() {
  # Find directories containing .terraform-docs.yml up to 5 levels deep
  echo "🔍 Searching for .terraform-docs.yml files up to 5 levels deep..."
  while IFS= read -r dir; do
    if [[ -z "$dir" ]]; then
      echo "❌ No .terraform-docs.yml files found."
      return 1
    fi

    echo "\n📁 Found .terraform-docs.yml in $dir"

    # Attempt to generate Terraform docs
    echo "🚀 Generating Terraform docs in $dir..."
    if (cd "$dir" && terraform-docs markdown -c .terraform-docs.yml . --output-file=README.md); then
      echo "✅ Terraform docs generated successfully in $dir"
    else
      echo "❌ Error generating Terraform docs in $dir"
    fi
  done < <(find . -maxdepth 5 -type f -name ".terraform-docs.yml" -exec dirname {} \; | sort -u)
}

# Alias definition for both bash and zsh
alias tfdocgen='tfdocgen'
