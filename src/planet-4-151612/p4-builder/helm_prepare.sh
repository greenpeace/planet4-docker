#!/usr/bin/env bash
set -eu

release_exists=$(helm list -q | grep -w "${HELM_RELEASE}" | xargs)

if [[ -z "$release_exists" ]]
then
  echo "Helm: ${HELM_RELEASE} does not exist: first deploy"
  exit 0
fi

release_status=$(helm status "${HELM_RELEASE}" -o json | jq '.info.status.code' | xargs)

if [[ $release_status = "1" ]]
then
  echo "Helm: ${HELM_RELEASE} is in a good state"
  exit 0
fi

echo "Helm: ${HELM_RELEASE} is in a failed state"

release_revision=$(helm history "${HELM_RELEASE}" | tail -1 | awk '{ print $1 }' | xargs)

if [[ $release_revision = "1" ]]
then
  echo "Helm: ${HELM_RELEASE} is first revision, purging"
  helm delete --purge "${HELM_RELEASE}"
  exit 0
fi

echo "Helm: ${HELM_RELEASE} has a previous revision - rolling back..."
previous=$(helm history "${HELM_RELEASE}" | tail -2 | head -1 | awk '{ print $1 }')
helm rollback "${HELM_RELEASE}" "$previous"
