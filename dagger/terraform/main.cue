package tfdocs

import(
  "universe.dagger.io/alpine"
  "universe.dagger.io/bash"
  "dagger.io/dagger"
  "dagger.io/dagger/core"


#Generate: {
	bash.#Run & {
		script: contents: """
			echo "Hello from my package!"
		"""
	}
}
