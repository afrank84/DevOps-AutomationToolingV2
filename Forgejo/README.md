# Forgejo runner installation

## [get-forgejo-runner-installed.sh](get-forgejo-runner-installed.sh)

Creates `~/.forgejo-runner`, maps x86_64/aarch64 to amd64/arm64, queries Forgejo's
latest runner release name, downloads the corresponding Linux binary, marks it
executable, and moves it to `/usr/local/bin/forgejo-runner` with sudo.

Requires Bash, curl, jq, wget, sudo, and access to `data.forgejo.org` and
`code.forgejo.org`. Invoke with Bash on a supported Linux architecture. It prints
the version and the next command, `forgejo-runner register`; it does not register,
start a daemon, install a service, or configure an execution backend.

It downloads a moving latest version without verifying a release checksum or
signature in the script and can overwrite an installed binary. Review an
official verified installation path before running. No installer was executed
for this documentation.
