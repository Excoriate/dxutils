## GitLab TF Module inspector
This is a simple script that will analyze a certain GitLab path (group, or subgroups), and it'll identify all the existing
[Terraform](https://www.terraform.io/) modules that has or not using a certain module.

>**NOTE**: It's required to **clone** "in memory" — so ensure that the paths analyzed doesn't include your whole GitLab organization if it's too big.
> It's recommended to use a group/subgroup path.

---
### Pre-requisites
- [Git](https://git-scm.com/)
- [Golang](https://golang.org/)

### Usage
Export your GitLab token as an environment variable:
```bash
export GITLAB_PRIVATE_TOKEN=<your-gitlab-token>
```
Run it
```bash
go run main.go -path=/Users/my-user/@code/ -tf-module="gitlab.com/my-group/my-module"
# or if you want to exclude certain modules
go run main.go -path=/Users/my-user/@code/ -tf-module="gitlab.com/my-group/my-module" -exclude="group-that-it-should-be-excluded"
```
It's important to mention that the `-exclude` flag is optional, and it'll ignore those groups/projects/repos analyzed
that matches the string provided in any part of the path.

### Options allowed
| Option     | Description                                                                                                                        |
|------------|------------------------------------------------------------------------------------------------------------------------------------|
| -group     | The `gitlab` path where your group/subgroup reside. It's not required to include https://gitlab.com, that's managed by the script. |
| -tf-module | The `gitlab` path of the module that you want to analyze.                                                                          |
| -exclude   | The `gitlab` path of the group/subgroup that you want to exclude from the analysis.                                                |

