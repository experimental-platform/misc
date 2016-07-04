#!/usr/bin/env bash

set -eu

SSID=${1:-""}
SINGLE_COMMAND=${2:-""}

SSH="sshpass -p $SSH_PASSWORD ssh platform@10.42.0.1 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

test_box() {
	local SSID=$1

	nmcli device wifi rescan
	nmcli device wifi connect "$SSID" password "$WIFI_PASSWORD"
	echo "Successfully connected to SSID '$SSID'"
	sleep 2

	IP="$(nmcli device show "$INTERFACE" | awk '{if($1=="IP4.ADDRESS[1]:") print $2}' | sed 's:/[0-9]*$::')"
	echo "Local IP is: $IP"

	if [ ! -z "$SINGLE_COMMAND" ]; then
		$SSH -C "$SINGLE_COMMAND"
	else
		$SSH -C 'source /etc/profile; test-everything'
	fi
}

cleanup() {
	nmcli device disconnect "$INTERFACE"
	nmcli c | awk '{if($4=="802-11-wireless"){print $3}; if($3=="802-11-wireless"){print $2}}' | xargs -L1 nmcli c delete
}

WLAN_CARDS=( $(nmcli device | awk '{if($2=="wifi"){print$1}}') )

if [ ${#WLAN_CARDS[@]} -ne 1 ]; then
	echo "Found ${#WLAN_CARDS[@]} Wi-Fi devices"
	exit 1
else
	INTERFACE=${WLAN_CARDS[0]}
fi

if [ -z "$SSID" ]; then 
	SSIDS=( $(nmcli --fields SSID,BSSID device wifi list | awk '{if ($1 ~ "^Protonet-[A-F0-9]{12,12}$") {print $1}}') )
	nmcli device wifi rescan
	echo "Detected box Wi-Fi BSSIDs:"
	for net in ${SSIDS[@]}; do
		echo " - $net"
	done
else
	echo "The interface is $INTERFACE"
	trap "cleanup" EXIT
	test_box "$SSID"
fi

exit 0

