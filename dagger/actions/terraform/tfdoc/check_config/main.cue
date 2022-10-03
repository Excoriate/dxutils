package tfdoc_check_config

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/alpine"
	"universe.dagger.io/docker"
	"universe.dagger.io/bash"
)

// Working directory to operate, inside the container.s
_workdir: "var/workdir"
_workdir_tf: _workdir + "/terraform"


#TFDocCheck: {
	srcTFModules: dagger.#FS

	// Current working directory into the container.
	_current: core.#Source & {
		path: "./src"
		include: ["tfdocs-checker.sh", "utils/*.sh"]
	}

	// Build docker image
	_build: docker.#Build & {
		steps: [
			// Build the image
			alpine.#Build & {
				packages: {
					bash: {}
					curl: {}
					jq: {}
				}
			},
			// Copy the terraform modules to check.
			docker.#Copy & {
				contents:  srcTFModules
				dest: _workdir_tf
			},

			// Copy the scripts that should run inside the container.
			docker.#Copy & {
				contents: _current.output
				dest: _workdir
			},
		]
	}

	_image: _build.output

	_inspect: bash.#Run & {
		input: _build.output
		script: contents: """
			echo "Terraform modules to check:"
			echo "-----------------------------------------"
			ls -ltrah var/workdir/terraform
			echo

			echo "Current working directory:"
			echo "-----------------------------------------"
			pwd
			ls -ltrah var/workdir
			echo
			"""
		always: true
	}

	_execute_compute: bash.#Run & {
		input: _image
		script: contents: """
						cd var/workdir
						./tfdocs-checker.sh --dir=terraform/compute
						"""
		}

	_execute_networking: bash.#Run & {
		input: _image
		script: contents: """
						cd var/workdir
						./tfdocs-checker.sh --dir=terraform/networking
						"""
		}

	_execute_storage: bash.#Run & {
		input: _image
		script: contents: """
						cd var/workdir
						./tfdocs-checker.sh --dir=terraform/storage
						"""
		}

}

