#!/usr/bin/env bash

set -eu

TMPFILE=$(mktemp)

mkdir -p "$HOME/bin"
echo 'export PATH="$PATH:$HOME/bin"' >>  "$HOME/.profile"

curl -L 'https://github.com/appc/acbuild/releases/download/v0.2.2/acbuild.tar.gz' | tar xfz - -C "$HOME/bin"

