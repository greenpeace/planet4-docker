#!/usr/bin/env bash
set -eu

release_status=$(helm status "${HELM_RELEASE}" -o json | jq '.info.status.code')

if [[ ${release_status} = "1" ]]
then
  # FIXME: curl output to Rocketchat API
  echo "Helm release ${HELM_RELEASE} successful"
  ./flush_redis.sh
  exit 0
fi

echo "ERROR: Helm release ${HELM_RELEASE} failed to deploy"
helm status "${HELM_RELEASE}"
exit 1
