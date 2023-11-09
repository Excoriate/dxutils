package main

import (
	"flag"
	"fmt"
	"os"
	"strings"
	"sync"

	"github.com/go-git/go-git/v5"
	"github.com/go-git/go-git/v5/plumbing/object"
	"github.com/go-git/go-git/v5/storage/memory"
	"github.com/pterm/pterm"
	"github.com/xanzy/go-gitlab"
)

var wg sync.WaitGroup
var excludeFlag string
var moduleFlag string
var reposWithModule []string
var reposWithoutModule []string
var reposExcluded []string
var mu sync.Mutex // Mutex to safely append to the slices

func main() {
	token := os.Getenv("GITLAB_PRIVATE_TOKEN")
	if token == "" {
		pterm.Fatal.Println("GITLAB_PRIVATE_TOKEN environment variable is not set.")
		return
	}
	gitLabClient, err := gitlab.NewClient(token)
	if err != nil {
		pterm.Fatal.Println("Failed to create GitLab client:", err)
		return
	}

	groupFlag := flag.String("group", "", "The GitLab group/subgroup path (required)")
	flag.StringVar(&moduleFlag, "tf-module", "", "Terraform module source string to search for (required)")
	flag.StringVar(&excludeFlag, "exclude", "", "String to exclude projects from analysis")
	flag.Parse()

	if *groupFlag == "" || moduleFlag == "" {
		flag.Usage()
		os.Exit(1)
	}

	pterm.DefaultSection.Println(fmt.Sprintf("Searching for Terraform module usage in repositories under %s...", *groupFlag))
	wg.Add(1)
	go searchRepositories(gitLabClient, *groupFlag, excludeFlag)

	wg.Wait()

	totalProjects := len(reposWithModule) + len(reposWithoutModule) + len(reposExcluded)
	pterm.DefaultSection.Printf("Total Projects Evaluated: %d\nRepos Using the Module: %d\nRepos Not Using the Module: %d\nExcluded Repos: %d\n",
		totalProjects, len(reposWithModule), len(reposWithoutModule), len(reposExcluded))

	pterm.DefaultSection.Println("Search Summary")
	createSummaryTable()
}

func createSummaryTable() {
	reposTable := pterm.TableData{{"Project Path", "Uses Module", "Excluded"}}

	addToTable := func(repoList []string, usesModule string, excluded string) {
		for _, repo := range repoList {
			reposTable = append(reposTable, []string{repo, usesModule, excluded})
		}
	}

	addToTable(reposWithModule, "Yes", "")
	addToTable(reposWithoutModule, "No", "")
	addToTable(reposExcluded, "-", "Yes")

	pterm.DefaultTable.WithHasHeader().WithData(reposTable).Render()
}

func searchRepositories(client *gitlab.Client, group string, exclude string) {
	defer wg.Done()

	opt := &gitlab.ListGroupProjectsOptions{
		ListOptions:      gitlab.ListOptions{PerPage: 10},
		IncludeSubGroups: gitlab.Bool(true),
	}
	for {
		projects, resp, err := client.Groups.ListGroupProjects(group, opt)
		if err != nil {
			pterm.Fatal.WithShowLineNumber(true).Println("Error fetching projects:", err)
			return
		}

		for _, project := range projects {
			if exclude != "" && strings.Contains(project.PathWithNamespace, exclude) {
				mu.Lock()
				reposExcluded = append(reposExcluded, project.PathWithNamespace)
				mu.Unlock()
				continue
			}
			wg.Add(1)
			go searchProjectForModule(project, moduleFlag)
		}

		if resp.CurrentPage >= resp.TotalPages {
			break
		}
		opt.Page = resp.NextPage
	}
}

func searchProjectForModule(project *gitlab.Project, module string) {
	defer wg.Done()

	r, err := git.Clone(memory.NewStorage(), nil, &git.CloneOptions{
		URL: project.SSHURLToRepo,
	})

	if err != nil {
		pterm.Error.Println("Error cloning project:", err)
		return
	}

	ref, err := r.Head()
	if err != nil {
		pterm.Error.Println("Error getting HEAD reference:", err)
		return
	}

	commit, err := r.CommitObject(ref.Hash())
	if err != nil {
		pterm.Error.Println("Error getting commit object:", err)
		return
	}

	tree, err := commit.Tree()
	if err != nil {
		pterm.Error.Println("Error getting commit tree:", err)
		return
	}

	containsModule := false
	err = tree.Files().ForEach(func(f *object.File) error {
		if strings.HasSuffix(f.Name, ".tf") {
			content, _ := f.Contents()
			if strings.Contains(content, module) {
				containsModule = true
				return nil
			}
		}
		return nil
	})

	mu.Lock() // Lock the mutex to safely access the slices
	if containsModule {
		reposWithModule = append(reposWithModule, project.PathWithNamespace)
	} else {
		reposWithoutModule = append(reposWithoutModule, project.PathWithNamespace)
	}
	mu.Unlock() // Unlock the mutex
}
