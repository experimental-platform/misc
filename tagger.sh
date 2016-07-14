#!/usr/bin/env bash

set -ue
set -o pipefail

DOCKER_TOKEN=""
TIMESTAMP="$(date -u '+%Y-%m-%d-%H%M')"
ISOTIMESTAMP="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
NEWBUILDNUM=""
DEFAULT_SOURCE_TAG="development"
SOURCE_TAG="$DEFAULT_SOURCE_TAG"
DEFAULT_TARGET_TAG="soul3"
TARGET_TAG="$DEFAULT_TARGET_TAG"
JSON_BRANCH="master"
COMMIT="false"
RELEASE_NOTES_URL=""

load_image_list() {
	local URL="https://raw.githubusercontent.com/protonet/builds/master/${SOURCE_TAG}.json"
	IMAGESJSON="$(curl --fail --silent "$URL" | jq ".[0].images | keys | map({(.):\"$TIMESTAMP\"}) | add")"
	IMAGES="$(echo "$IMAGESJSON" | jq 'keys[]' --raw-output | sed 's:^quay.io/::')"
}

prepare_repo() {
	CLONEDIR=$(mktemp -d)
	trap "rm -rf '$CLONEDIR'" SIGINT SIGTERM EXIT

	git clone -q 'git@github.com:protonet/builds.git' "$CLONEDIR"
	git -C "$CLONEDIR" checkout "$JSON_BRANCH" &>/dev/null

	JSONFILE="$CLONEDIR/$TARGET_TAG.json"
}

retag_image() {
  local IMAGE ID OLD_TAG NEW_TAG
  IMAGE="$1"
	OLD_TAG="$2"
	NEW_TAG="$3"

  if echo "$IMAGE" | grep -q '^experimentalplatform/'; then
    TOKEN="$TOKEN_PLATFORM"
  elif echo "$IMAGE" | grep -q '^protonetinc/'; then
    TOKEN="$TOKEN_PROTONET"
  else
    echo "Unknown image namespace"
    exit 1
  fi

  ID="$(get_tag_image "$IMAGE" "$OLD_TAG")"
  set_tag_image "$IMAGE" "$NEW_TAG" "$ID"
}

get_tag_image() {
  local NAME TAG
  NAME="$1"
  TAG="$2"
  OUT="$(curl --silent "https://quay.io/api/v1/repository/$NAME/tag/" -H "Authorization: Bearer $TOKEN" | jq --arg tag "$TAG" '.tags[] | select(.name == $tag) | select(.end_ts == null) | .docker_image_id' --raw-output)"
  echo "$OUT"
}

set_tag_image() {
  local NAME TAG ID
  NAME="$1"
  TAG="$2"
  ID="$3"

  curl --silent -X PUT "https://quay.io/api/v1/repository/$NAME/tag/$TAG" -H 'Content-Type: application/json' -H "Authorization: Bearer $TOKEN" -d "$(jq -n --arg id "$ID" '{"image": $id}' )"
}

retag_all() {
	local OLD_TAG NEW_TAG
	OLD_TAG="$1"
	NEW_TAG="$2"

	for image in $IMAGES; do
	  echo -en "Tagging \"${image}:${OLD_TAG}\" with \"${NEW_TAG}\"... "
		retag_image "$image" "$OLD_TAG" "$NEW_TAG"
		echo "."# primarily add a newline
	done
}

print_usage() {
	echo "Usage: $0 [-h|--help] [-b|--build buildnumber] [--source-tag tag] [--target-tag tag] -u|--url url [--commit]"
	echo "Flags:"
	echo -e "\t -h|--help\t Show this help text."
	echo -e "\t -b|--build\t Manually specify the build number to be placed inside the JSON."
	echo -e "\t --commit\t\t Commit the changes. Will make a dry run without this flag."
	echo -e "\t --source-tag\t Registry tag to be retagging from (default: $DEFAULT_SOURCE_TAG)"
	echo -e "\t --target-tag\t Registry tag to be retagging to (default: $DEFAULT_TARGET_TAG)"
	echo -e "\t -u|--url\t Release notes URL"
}

update_json() {
	local JSON BUILDNUM

	JSON="$(< "$JSONFILE")"
	BUILDNUM=$(echo "$JSON" | jq '.[0].build')
	if [ -z "$NEWBUILDNUM" ]; then
		echo "Getting build number from docker image"
		GS_IMAGE="quay.io/protonetinc/german-shepherd:$SOURCE_TAG"
		echo "Downloading '$GS_IMAGE'"
		docker pull "$GS_IMAGE" &>/dev/null
		echo "Download complete"
		NEWBUILDNUM=$(docker run -it --rm "$GS_IMAGE" cat /soul/source/BUILD_NUMBER | tr --delete '\r')
	else
		echo "Using build number $NEWBUILDNUM from command line"
	fi
	echo "Old build version: $BUILDNUM"
	echo "New build version: $NEWBUILDNUM"

	JQCMD="(.[0].build = $NEWBUILDNUM) | (.[0].published_at = \"$ISOTIMESTAMP\") | (.[0].url = \"$RELEASE_NOTES_URL\") | (.[0].images = \$images)"
	JSON="$(jq --argjson images "$IMAGESJSON" "$JQCMD" <<< "${JSON}")"
	echo "$JSON" > "$JSONFILE"
	git -C "$CLONEDIR" add "$TARGET_TAG.json"
	git -C "$CLONEDIR" commit -m "release at $ISOTIMESTAMP"

	if [[ $COMMIT == "true" ]]; then
	        git -C "$CLONEDIR" push
	else
	        echo -e "New JSON:\n$JSON"
	fi
}

while [[ $# > 0 ]]; do
	case $1 in
		--commit)
			COMMIT="true"
			;;
		-b|--build)
			NEWBUILDNUM="$2"
			shift
		;;
		--source-tag)
			SOURCE_TAG="$2"
			shift
		;;
		--target-tag)
			TARGET_TAG="$2"
			shift
		;;
		-h|--help)
			print_usage
			exit 0
		;;
		-u|--url)
			RELEASE_NOTES_URL="$2"
			shift
		;;
		*)
			echo "Unknown option '$1'"
			print_usage
			exit 1
		;;
	esac

	shift
done

if [ -z "$RELEASE_NOTES_URL" ]; then
	echo "You must specify the release notes URL!"
	exit 1
fi

echo "Tag timestamp: $TIMESTAMP"
echo "ISO timestamp: $ISOTIMESTAMP"

prepare_repo
load_image_list

if [ $COMMIT == "true" ]; then
	retag_all "$SOURCE_TAG" "$TIMESTAMP"
	retag_all "$TIMESTAMP" "$TARGET_TAG"
else
	echo "Dry run. Would otherwise retag following images from '$SOURCE_TAG' to '$TIMESTAMP' and '$TARGET_TAG':"
  echo "$IMAGES" | sed 's/^/ * /'
fi

update_json
