package dxutils

import(
  "universe.dagger.io/alpine"
  "universe.dagger.io/bash"
  "dagger.io/dagger"
  "dagger.io/dagger/core"


#Run: {
    _img: alpine.#Build & {
        packages: bash: _
    }

    bash.#Run & {
        always: true
        input:  _img.output
    }
}
