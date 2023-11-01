## GitLab Cloner
This is a simple script to clone all the projects from a GitLab server.
It will clone all the projects from the GitLab SAAS instance, and
will clone all the projects to your local machine.
The process works using the powerful [Go Rutines](https://tour.golang.org/concurrency/1) to clone all the projects in parallel.

>**NOTE**: Ensure you have enough disk space to clone all the projects. If you aren't sure, just run `df -h` to check.

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
go run main.go -path=/Users/my-user/@code/ -group="myproject/subgroup"
go run main.go -path=/Users/my-user/@code/ -group="myproject/subgroup" -timeout=5m
```

### Options allowed
| Option   | Description                                                                                                                        |
|----------|------------------------------------------------------------------------------------------------------------------------------------|
| -group   | The `gitlab` path where your group/subgroup reside. It's not required to include https://gitlab.com, that's managed by the script. |
| -timeout | In minutes. By default, it's set in `2m`. Modify accordingly if you have projects/repositories bigger in size.                     |
| -path    | Where you want to store the cloned repositories.                                                                                   |

> NOTE: The Cloning is [idempotent](https://en.wikipedia.org/wiki/Idempotence), so you can run it multiple times without any issues.
> It'll detect if there's an already cloned repository, and if it does it'll `pull` it instead of `clone` it.
