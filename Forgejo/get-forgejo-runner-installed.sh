#!/bin/bash

set -e

mkdir -p ~/.forgejo-runner
cd ~/.forgejo-runner

ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
RUNNER_VERSION=$(curl -s https://data.forgejo.org/api/v1/repos/forgejo/runner/releases/latest | jq -r '.name' | cut -c2-)
FORGEJO_URL="https://code.forgejo.org/forgejo/runner/releases/download/v${RUNNER_VERSION}/forgejo-runner-${RUNNER_VERSION}-linux-${ARCH}"

wget -O forgejo-runner "$FORGEJO_URL"
chmod +x forgejo-runner

sudo mv forgejo-runner /usr/local/bin/
forgejo-runner --version

echo
echo "Runner installed."
echo "Current directory: ~/.forgejo-runner"
echo
echo "Next step:"
echo "forgejo-runner register"
