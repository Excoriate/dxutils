package terraform

import(
  "universe.dagger.io/alpine"
  "universe.dagger.io/bash"
)

#Generate: {
	bash.#Run & {
		always: true
		script: contents: """
			echo "Hello from my package!"
		"""
	}
}
