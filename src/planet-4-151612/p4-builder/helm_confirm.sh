#!/usr/bin/env bash
set -eu

release_status=$(helm status "${HELM_RELEASE}" -o json | jq '.info.status.code')

if [[ ${release_status} = "1" ]]
then
  echo "Helm release ${HELM_RELEASE} successful"
  ./flush_redis.sh
  TYPE="Helm Deployment" EXTRA_TEXT="\`\`\`History:
$(helm history "${HELM_RELEASE}" --max=5)
\`\`\`" "${HOME}/scripts/notify-job-success.sh"
  exit 0
fi

echo "ERROR: Helm release ${HELM_RELEASE} failed to deploy"
TYPE="Helm Deployment" EXTRA_TEXT="\`\`\`Status:
$(helm status "${HELM_RELEASE}")

History:
$(helm history "${HELM_RELEASE}" --max=5)
\`\`\`" "${HOME}/scripts/notify-job-failure.sh"
exit 1
