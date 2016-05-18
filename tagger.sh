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
SURE="false"

IMAGES="
experimentalplatform/skvs
experimentalplatform/ptw
experimentalplatform/afpd
experimentalplatform/http-proxy
experimentalplatform/hostname-avahi
experimentalplatform/hardware
experimentalplatform/systemd-proxy
experimentalplatform/smb
experimentalplatform/pulseaudio
experimentalplatform/haproxy
experimentalplatform/hostname-smb
experimentalplatform/hostapd
experimentalplatform/app-manager
experimentalplatform/central-gateway
experimentalplatform/dnsmasq
experimentalplatform/dokku
experimentalplatform/frontend
experimentalplatform/monitoring
experimentalplatform/configure

experimentalplatform/mysql
experimentalplatform/elasticsearch
experimentalplatform/redis
experimentalplatform/rabbitmq

protonetinc/german-shepherd
protonetinc/soul-backup
protonetinc/soul-nginx
protonetinc/soul-protosync
protonetinc/soul-smb
"

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
		retag_image "$image" "$OLD_TAG" "$NEW_TAG"
	done
}

get_shepherd_build_number() {
	docker run -it --rm "quay.io/protonetinc/german-shepherd:$SOURCE_TAG" cat /soul/source/BUILD_NUMBER
}

print_usage() {
	echo "Usage: $0 [-h|--help] [-b|--build buildnumber] [--sure]"
	echo "Flags:"
	echo -e "\t -h|--help\t Show this help text."
	echo -e "\t -b|--build\t Manually specify the build number to be placed inside the JSON."
	echo -e "\t --sure\t\t Commit the changes. Will make a dry run without this flag."
	echo -e "\t --source-tag\t Registry tag to be retagging from (default: $DEFAULT_SOURCE_TAG)"
	echo -e "\t --target-tag\t Registry tag to be retagging to (default: $DEFAULT_TARGET_TAG)"
}

update_json() {
	local CLONEDIR JSON BUILDNUM

	CLONEDIR=$(mktemp -d)
	trap "rm -rf '$CLONEDIR'" SIGINT SIGTERM EXIT
	git clone -q 'git@github.com:protonet/builds.git' "$CLONEDIR"
	git -C "$CLONEDIR" checkout "$JSON_BRANCH" &>/dev/null

	JSONFILE="$CLONEDIR/$TARGET_TAG.json"
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

	JQCMD="(.[0].build = $NEWBUILDNUM) | (.[0].published_at = \"$ISOTIMESTAMP\")"
	JSON="$(echo "${JSON}" | jq "$JQCMD")"
	echo "$JSON" > "$JSONFILE"
	git -C "$CLONEDIR" add "$TARGET_TAG.json"
	git -C "$CLONEDIR" commit -m "release at $ISOTIMESTAMP"

	if [[ $SURE == "true" ]]; then
	        git -C "$CLONEDIR" push
	else
	        echo -e "New JSON:\n$JSON"
	fi
}

while [[ $# > 0 ]]; do
	case $1 in
		--sure)
			SURE="true"
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
		*)
			echo "Unknown option '$1'"
			print_usage
			exit 1
		;;
	esac

	shift
done

echo "Tag timestamp: $TIMESTAMP"
echo "ISO timestamp: $ISOTIMESTAMP"

if [ $SURE == "true" ]; then
	retag_all "$SOURCE_TAG" "$TIMESTAMP"
	retag_all "$TIMESTAMP" "$TARGET_TAG"
else
	echo "Dry run. Would otherwise retag '$SOURCE_TAG' to '$TIMESTAMP' and '$TARGET_TAG'"
fi

update_json
