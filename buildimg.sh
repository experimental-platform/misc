#!/usr/bin/env bash

set -eu

# e.g. 'platform-dokku'
REPONAME=$(echo $TRAVIS_REPO_SLUG | cut -f2 -d '/')
# e.g. 'dokku'
SERVICENAME=$(echo $REPONAME | sed 's/^platform-//')

TAGNAME="quay.io/experimentalplatform/$SERVICENAME:$TRAVIS_BRANCH"

docker build -t "${TAGNAME}" .

if [ -e "test-image" ]; then
  if [ -x "test-image" ]; then
    ./test-image "${TAGNAME}" || exit 1
  else
    echo "Found a test-image script, but it's not executable."
    exit 1
  fi
fi

if [ "${TRAVIS_BRANCH}" == "master" ]; then
  echo -e "\n\nWe're not uploading master anywhere."
elif [ "${TRAVIS_PULL_REQUEST}" != "false" ]; then
  echo -e "\n\nWe're not uploading images from pull requests."
else
  docker login -e 'none' -u "$QUAY_USER" -p "$QUAY_PASS" quay.io
  docker push "$TAGNAME"
fi
