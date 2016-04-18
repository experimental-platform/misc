#!/bin/bash
set -e

SRC_PATH=$(pwd)
PROJECT_NAME="github.com/$TRAVIS_REPO_SLUG"

export GO15VENDOREXPERIMENT=1
curl -L https://raw.githubusercontent.com/experimental-platform/misc/master/install-glide.sh | sh
cp $HOME/bin/glide .
docker run -v "${SRC_PATH}:/go/src/$PROJECT_NAME" -w "/go/src/$PROJECT_NAME" -e GO15VENDOREXPERIMENT=1 golang:1.5 /bin/bash -c "./glide up && CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -v -ldflags='-s -w'"

wget 'https://github.com/Yelp/dumb-init/releases/download/v1.0.1/dumb-init_1.0.1_amd64' -O dumb-init && chmod +x dumb-init

