#!/usr/bin/env bash

set -eu
set -o pipefail
set -x

BASEPATH=${BASEPATH:-go}

curl -L https://raw.githubusercontent.com/experimental-platform/misc/master/install-glide.sh | bash -s v0.11.1

mkdir -p binaries

for tooldir in ${BASEPATH}/*; do
  tool_name="$(basename $tooldir)"
  echo "Building $tool_name"

  echo " * Gliding up"
  docker run -v "$HOME/bin/glide:/usr/bin/glide:ro" -v "$(readlink -f $tooldir):/go/src/$tool_name" -w "/go/src/$tool_name" golang:1.7 glide up
  echo " * Building"
  docker run -v "$HOME/bin/glide:/usr/bin/glide:ro" -v "$(readlink -f $tooldir):/go/src/$tool_name" -w "/go/src/$tool_name" golang:1.7 go build
  echo " * Testing"
  docker run -v "$HOME/bin/glide:/usr/bin/glide:ro" -v "$(readlink -f $tooldir):/go/src/$tool_name" -w "/go/src/$tool_name" golang:1.7 go test -v

  mv "$tooldir/$tool_name" "binaries/"
done
