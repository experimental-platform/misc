#!/usr/bin/env bash

set -ue
set -o pipefail

DOCKER_TOKEN=""
OLD_TAG="$1"
NEW_TAG="$2"

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

protonetinc/german-shepherd
protonetinc/soul-backup
protonetinc/soul-nginx
protonetinc/soul-protosync
protonetinc/soul-smb
"

retag_image() {
  local IMAGE ID
  IMAGE="$1"

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

for image in $IMAGES; do
  retag_image "$image"
done

