package tfdoc_check

import (
	"dagger.io/dagger"
	"github.com/Excoriate/dxutils/dagger/actions/terraform/tfdoc/tfdoc_check"
)

dagger.#Plan & {
	// read terraform folders.
	client: filesystem: "./is_valid": read: {
		contents: dagger.#FS
		exclude: [".terraform"]
	}

	actions: {
		check: tfdoc_check.#TFDocCheck & {
			srcTFModules: client.filesystem."./is_valid".read.contents
		}
	}
}
