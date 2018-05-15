#!/usr/bin/env bash
set -eu

release_status=$(helm status "${HELM_RELEASE}" -o json | jq '.info.status.code')

status_text=$(helm status "${HELM_RELEASE}")

if [[ ${release_status} = "1" ]]
then
  echo "Helm release ${HELM_RELEASE} successful"
  ./flush_redis.sh
  TYPE="Helm Deployment" EXTRA_TEXT="\`\`\`History:
$(helm history "${HELM_RELEASE}" --max=5)

Status:
${status_text}\`\`\`" "${HOME}/scripts/notify-job-success.sh"
  exit 0
fi

echo "ERROR: Helm release ${HELM_RELEASE} failed to deploy"
TYPE="Helm Deployment" EXTRA_TEXT="\`\`\`History:
$(helm history "${HELM_RELEASE}" --max=5)

Status:
${status_text}\`\`\`" "${HOME}/scripts/notify-job-failure.sh"
exit 1
