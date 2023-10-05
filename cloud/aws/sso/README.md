## SSO Selector
Simple script to automatically select the correct AWS SSO profile based on the current AWS account.

### Pre-requisites
- [AWS CLI](https://aws.amazon.com/cli/)
- [AWS SSO CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- [Gum](https://github.com/charmbracelet/gum)
- [AWS2-wrap](https://github.com/linaro-its/aws2-wrap)

### Usage
1. Install the pre-requisites
2. Configure it as an alias (recommended). E.g:
```bash
alias awsconnect=_sso_select
```
Ensure you've added this function to your `.bashrc` or `.zshrc` file.
