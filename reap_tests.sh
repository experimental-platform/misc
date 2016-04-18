#!/usr/bin/env bash

set -eu

INSTANCESJSON="$(aws ec2 describe-instances --filter 'Name=tag:Test,Values=true' --filter 'Name=instance-state-name,Values=running')"
IDS="$(echo "$INSTANCESJSON" | jq '.Reservations[].Instances[].InstanceId' --raw-output)"

aws ec2 terminate-instances --instance-ids $IDS

