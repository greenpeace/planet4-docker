#!/usr/bin/env bash
set -exu

NEWRELIC_APPLICATION_ID="${NEWRELIC_APPLICATION_ID:-$(newrelic-get-application-id.sh)}"

revision=$(helm ls "${HELM_RELEASE}" | grep "${HELM_RELEASE}" | tr -s '\t' | tr '\t' ' ' | cut -d" " -f 2)
changelog=${CIRCLE_COMPARE_URL}
description="${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME} @${CIRCLE_BRANCH:-${CIRCLE_TAG}}"
user=${CIRCLE_USERNAME}

# shellcheck disable=SC2016
json=$(jq -n \
  --arg REVISION "$revision" \
  --arg CHANGELOG "$changelog" \
  --arg DESCRIPTION "$description" \
  --arg USER "$user" \
'{
  "deployment": {
    "revision": $REVISION,
    "changelog": $CHANGELOG,
    "description": $DESCRIPTION,
    "user": $USER
  }
}')

newrelic-post.sh \
  "https://api.newrelic.com/v2/applications/${NEWRELIC_APPLICATION_ID}/deployments.json" \
  "$json"
