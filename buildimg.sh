#!/usr/bin/env bash

set -eu

# e.g. 'platform-dokku'
REPONAME=$(echo $TRAVIS_REPO_SLUG | cut -f2 -d '/')
# e.g. 'dokku'
SERVICENAME=$(echo $REPONAME | sed 's/^platform-//')

# Allow to set custom quay.io organization from ENV
QUAY_ORG=${QUAY_ORG:-experimentalplatform}

TAGNAME="quay.io/$QUAY_ORG/$SERVICENAME:$TRAVIS_BRANCH"

docker build --tag "${TAGNAME}" \
  --label build_branch="$TRAVIS_BRANCH" \
  --label build_number="$TRAVIS_BUILD_NUMBER" \
  --label build_commit="$TRAVIS_COMMIT" \
  --label build_commit_range="$TRAVIS_COMMIT_RANGE" \
  --label build_job_number="$TRAVIS_JOB_NUMBER" \
  .

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
  docker login -u "$QUAY_USER" -p "$QUAY_PASS" quay.io
  docker push "$TAGNAME"
fi
