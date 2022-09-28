package dx-utils

import(
  "universe.dagger.io/alpine"
  "universe.dagger.io/bash"
)

#Run: {
	bash.#Run & {
		always: true
		script: contents: """
			echo "Hello from my package!"
		"""
	}
}
