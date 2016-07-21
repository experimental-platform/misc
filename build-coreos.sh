#!/usr/bin/env bash

set -eu
set -o pipefail

COREOS_BUILD=1010
PROTONET_OVERLAY_COMMIT="087d52e7d3158119bafa5938c865b2ef5cfaa0bd"
DONT_BUILD="false"

print_usage() {
	echo "usage: $0 [--help]"
	echo "Flags:"
	echo -e "\t--help\t\tShow this help text."
	echo -e "\t--dont-build\tJust prepare a build environment."
	echo -e "\t--commit\tprotonet-overlay commit to use"
}

while [[ $# > 0 ]]; do
	key="$1"
	case $key in 
		--help)
			print_usage
			exit 0
		;;
		--dont-build)
			DONT_BUILD="true"
		;;
		--commit)
			PROTONET_OVERLAY_COMMIT="$2"
			shift
		;;
		*)
			echo "Unknown flag '$key'"
			print_usage
			exit 1
		;;
	esac
	shift
done

BUILDDIR="$(mktemp -d)"
trap 'echo "BUILDDIR = $BUILDDIR"' EXIT

inject_protonet_overlay() {
	sed -i "/coreos\/coreos-overlay/a \ \ <project groups=\"minilayout\" name=\"protonet/protonet-overlay\" path=\"src/third_party/protonet-overlay\" revision=\"$PROTONET_OVERLAY_COMMIT\" upstream=\"refs/heads/master\"/>" "$BUILDDIR/.repo/manifests/release.xml"

	cd "$BUILDDIR"
	repo sync --force-sync

	sed -i "/^COREOS_OVERLAY=/a PROTONET_OVERLAY=\"\${REPO_ROOT}/src/third_party/protonet-overlay\"" "$BUILDDIR/src/scripts/update_chroot"
	sed -i -E 's/^(PORTDIR_OVERLAY=".*)"$/\1 ${PROTONET_OVERLAY}"/' "$BUILDDIR/src/scripts/update_chroot"
}

cd "$BUILDDIR"
repo init -b "build-$COREOS_BUILD" -m release.xml -u https://github.com/coreos/manifest.git
inject_protonet_overlay

$BUILDDIR/chromite/bin/cros_sdk -- ./setup_board --board amd64-usr --default

if [ "$DONT_BUILD" != "true" ]; then
	$BUILDDIR/chromite/bin/cros_sdk -- ./build_packages
	$BUILDDIR/chromite/bin/cros_sdk -- ./build_image prod
fi

