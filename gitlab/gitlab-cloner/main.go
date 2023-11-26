package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"github.com/go-git/go-git/v5/config"
	"os"
	"path/filepath"
	"sync"
	"time"

	"github.com/go-git/go-git/v5"
	"github.com/go-git/go-git/v5/plumbing"
	"github.com/pterm/pterm"
	"github.com/xanzy/go-gitlab"
)

type cloneTask struct {
	project       *gitlab.Project
	destDir       string
	DefaultBranch string
}

var wg sync.WaitGroup
var cloneTasksChan = make(chan cloneTask)
var totalTasks, doneTasks int
var totalBar, _ = pterm.DefaultProgressbar.WithTitle("Cloning Projects").Start() // declare totalBar with an initial value
var timeoutFlag = flag.String("timeout", "2m", "timeout duration for git operations")
var defaultBranch = "master"

func main() {
	token := os.Getenv("GITLAB_PRIVATE_TOKEN")
	if token == "" {
		pterm.Fatal.Println("GITLAB_PRIVATE_TOKEN not set")
	}

	gitLabClient, err := gitlab.NewClient(token)
	if err != nil {
		pterm.Fatal.Println("Failed to create GitLab client")
	}

	// Directory to clone repositories
	baseDir := flag.String("path", "./", "Path to clone repositories")
	// GitLab group/subgroup
	groupPath := flag.String("group", "", "GitLab group or subgroup to clone from")

	pterm.Info.Printf("Cloning projects from %s to %s\n", *groupPath, *baseDir)

	flag.Parse()

	if *groupPath == "" {
		pterm.Error.Println("Please specify a group/subgroup path with the -group option")
		os.Exit(1)
	}

	if _, err := time.ParseDuration(*timeoutFlag); err != nil {
		pterm.Error.Printf("Invalid timeout duration: %s", *timeoutFlag)
		os.Exit(1)
	}

	go cloneWorker(cloneTasksChan)

	// clone all repositories
	wg.Add(1)
	go cloneAllRepositories(gitLabClient, *groupPath, *baseDir)

	wg.Wait()
	close(cloneTasksChan)

	if totalTasks == 0 {
		pterm.Warning.Println("No projects found")
		return
	}

	_, _ = totalBar.Stop()

	pterm.Success.Printf("Cloned %d projects\n", doneTasks)
}

func cloneOrPullRepo(url string, path string, timeoutFlag string, defaultBranch string) error {
	duration, err := time.ParseDuration(timeoutFlag)
	if err != nil {
		return err
	}

	ctx, cancel := context.WithTimeout(context.Background(), duration)
	defer cancel()

	// Check if .git directory exists
	_, err = os.Stat(path + "/.git")
	if os.IsNotExist(err) { // If not exists, it is not a git repository, so clone.
		return cloneWithTimeout(ctx, url, path, defaultBranch)
	}

	// Else, it's already a repository, try pull.
	return pullWithTimeout(ctx, path, defaultBranch)
}

// cloneWithTimeout attempts to clone a repository at given url to a destination path, but will time out and abort the operation if it takes too long.
func cloneWithTimeout(ctx context.Context, url string, path string, defaultBranch string) error {
	ch := make(chan error)
	go func() {
		_, err := git.PlainClone(path, false, &git.CloneOptions{
			URL:           url,
			Progress:      os.Stdout,
			ReferenceName: plumbing.NewBranchReferenceName(defaultBranch),
			SingleBranch:  false,
		})
		ch <- err
	}()

	select {
	case err := <-ch:
		return err
	case <-ctx.Done():
		pterm.Error.Printf("Cloning %s timed out\n", url)
		return fmt.Errorf("cloning %s timed out", url) // If we timed out, return an error.
	}
}

func pullWithTimeout(ctx context.Context, path string, defaultBranch string) error {
	pterm.Info.Printf("Pulling %s\n", path)
	ch := make(chan error)
	go func() {
		r, err := git.PlainOpen(path)
		if err != nil {
			ch <- err
			return
		}
		w, err := r.Worktree()
		if err != nil {
			ch <- err
			return
		}

		// Fetch the latest commits from the origin remote
		err = r.Fetch(&git.FetchOptions{
			RemoteName: "origin",
			RefSpecs:   []config.RefSpec{"+refs/heads/*:refs/remotes/origin/*"},
			Force:      true,
		})
		if err != nil && !errors.Is(err, git.NoErrAlreadyUpToDate) {
			ch <- err
			return
		}

		// Gets the hash of the remote default branch
		ref, err := r.Reference(plumbing.NewRemoteReferenceName("origin", defaultBranch), true)
		if err != nil {
			ch <- err
			return
		}

		// Reset the current working directory to the fetched hash
		err = w.Reset(&git.ResetOptions{
			Commit: ref.Hash(),
			Mode:   git.HardReset,
		})
		ch <- err
	}()

	select {
	case err := <-ch:
		return err
	case <-ctx.Done():
		pterm.Error.Printf("Pulling in %s timed out\n", path)
		return fmt.Errorf("pulling in %s timed out", path)
	}
}

func cloneWorker(tasks <-chan cloneTask) {
	for task := range tasks {
		totalBar.UpdateTitle("Cloning " + task.project.PathWithNamespace)

		err := cloneOrPullRepo(task.project.SSHURLToRepo, task.destDir, *timeoutFlag, task.DefaultBranch)

		if err != nil {
			pterm.Warning.Printf("Failed to clone or update project %s: %s\n", task.project.PathWithNamespace, err)
			continue
		}

		doneTasks++

		if totalTasks > 0 {
			totalBar.Increment()
		}
	}
}

func cloneAllRepositories(client *gitlab.Client, group, baseDir string) {
	defer wg.Done()

	opt := &gitlab.ListGroupProjectsOptions{
		ListOptions: gitlab.ListOptions{
			PerPage: 100,
		},
		IncludeSubGroups: gitlab.Bool(true),
	}

	for {
		projects, resp, err := client.Groups.ListGroupProjects(group, opt)
		if err != nil {
			pterm.Error.Printf("Failed to list projects under group %s: %s\n", group, err)
			return
		}

		for _, project := range projects {
			destDir := filepath.Join(baseDir, project.PathWithNamespace)

			if project.Archived {
				continue // Skip archived projects.
			}

			var branchName string
			if project.DefaultBranch != "" {
				branchName = project.DefaultBranch
			} else {
				branchName = defaultBranch // Default branch name if not provided by GitLab
			}

			totalTasks++
			totalBar.WithTotal(totalTasks) // For the new clone tasks (if any)
			cloneTasksChan <- cloneTask{project: project, destDir: destDir, DefaultBranch: branchName}
		}

		if resp.CurrentPage >= resp.TotalPages {
			break
		}

		opt.Page = resp.NextPage
	}
}
