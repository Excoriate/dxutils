package dxutils

import(
  "universe.dagger.io/bash"
  "dagger.io/dagger"
  "dagger.io/dagger/core"


#Run: {
		bash.#Run & {
				script: contents: """
					Hello!!!
					"""
	}
}
