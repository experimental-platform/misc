#!/usr/bin/env bash

set -o errexit -o nounset

PROJECT=$1
JSONENV="{}"

while [ -n "${3-}" ]; do
  JSONENV=$(echo "$JSONENV" | jq --arg k ${2} --arg v ${3} '. + { ($k): ($v) }')
  shift 2
done

URL="https://api.travis-ci.org/repo/experimental-platform%2F$PROJECT/requests"
MESSAGE="Triggered by corebuilder cronjob on $(date)"

BODY="$(jq -n --arg msg "$MESSAGE" ".request.message |= \$msg | .request.config.env |= $JSONENV")"

curl -i -X POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Travis-API-Version: 3" \
  -H "Authorization: token $TRAVIS_TOKEN" \
  -d "$BODY" \
  $URL
