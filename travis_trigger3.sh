#!/usr/bin/env bash

set -o errexit -o nounset

PROJECT=""
ORG=""
JSONENV="{}"

function parse_options() {
  while [[ $# > 0 ]]; do
    key="$1"
    case $key in
      --organisation)
        ORG=$2
        shift 2
      ;;
      --project)
        PROJECT=$2
        shift 2
      ;;
      --env)
        JSONENV=$(jq --arg k ${2} --arg v ${3} '. + { ($k): ($v) }' <<< "$JSONENV")
        shift 3
      ;;
      *)
        echo "Unknown parameter '$key'"
        exit 1
      ;;
    esac
  done
}

parse_options $@

URL="https://api.travis-ci.org/repo/${ORG}%2F${PROJECT}/requests"
MESSAGE="Triggered by corebuilder cronjob on $(date)"

BODY="$(jq -n --arg msg "$MESSAGE" ".request.message |= \$msg | .request.config.env |= $JSONENV")"

curl -i -X POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Travis-API-Version: 3" \
  -H "Authorization: token $TRAVIS_TOKEN" \
  -d "$BODY" \
  $URL
