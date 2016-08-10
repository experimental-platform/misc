#!/usr/bin/env bash

set -eux

TMPFILE=$(mktemp)
TMPDIR=$(mktemp -d)

URL="https://github.com/Masterminds/glide/releases/download/0.6.1/glide-linux-amd64.zip"

if [ $# -eq 1 ]; then
  URL="https://github.com/Masterminds/glide/releases/download/$1/glide-$1-linux-amd64.zip"
fi

curl -L "$URL" > "$TMPFILE"
unzip "$TMPFILE" -d "$TMPDIR"
mkdir -p "$HOME/bin"
echo 'export PATH="$PATH:$HOME/bin"' >>  "$HOME/.profile"
mv "$TMPDIR/linux-amd64/glide" "$HOME/bin/glide"
#rm -rf "$TMPFILE" "$TMPDIR"
