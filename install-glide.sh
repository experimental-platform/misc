#!/usr/bin/env bash

set -eux

TMPFILE=$(mktemp)
TMPDIR=$(mktemp -d)

GLIDE_VERSION="v0.11.1"

if [ $# -eq 1 ]; then
  GLIDE_VERSION="$1"
fi

URL="https://github.com/Masterminds/glide/releases/download/$GLIDE_VERSION/glide-$GLIDE_VERSION-linux-amd64.zip"

curl -L "$URL" > "$TMPFILE"
unzip "$TMPFILE" -d "$TMPDIR"
mkdir -p "$HOME/bin"
echo 'export PATH="$PATH:$HOME/bin"' >>  "$HOME/.profile"
mv "$TMPDIR/linux-amd64/glide" "$HOME/bin/glide"
#rm -rf "$TMPFILE" "$TMPDIR"
