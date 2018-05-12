#!/usr/bin/env bash
set -uo pipefail

env | sort

helm upgrade --install --force --wait --timeout 300 "${HELM_RELEASE}" \
  --namespace "${HELM_NAMESPACE}" \
  -f secrets.yaml \
  --set dbDatabase="${WP_DB_NAME}" \
  --set exim.image.tag="${INFRA_VERSION}" \
  --set hostname="${APP_HOSTNAME}" \
  --set hostpath="${APP_HOSTPATH}" \
  --set newrelic.appname="${NEWRELIC_APPNAME}" \
  --set openresty.image.repository="${OPENRESTY_IMAGE}" \
  --set openresty.image.tag="${BUILD_TAG}" \
  --set php.image.repository="${PHP_IMAGE}" \
  --set php.image.tag="${BUILD_TAG}" \
  --set sqlproxy.cloudsql.instances[0].instance="${CLOUDSQL_INSTANCE}" \
  --set sqlproxy.cloudsql.instances[0].project="${GOOGLE_PROJECT_ID}" \
  --set sqlproxy.cloudsql.instances[0].region="${GCLOUD_REGION}" \
  --set sqlproxy.cloudsql.instances[0].port="3306" \
  --set wp.siteUrl="${APP_HOSTNAME}/${APP_HOSTPATH}" \
  --set wp.stateless.bucket="${WP_STATELESS_BUCKET}" \
  p4-helm-charts/wordpress 2>&1 | tee helm_output.txt

if [[ $? -ne 0 ]]
then
  echo "ERROR: Helm release ${HELM_RELEASE} failed to deploy"
  TYPE="Helm Deployment" EXTRA_TEXT="\`\`\`
Environment:
$(env | sort)
History:
$(helm history "${HELM_RELEASE}" --max=5)
Build:
$(cat helm_output.txt)
\`\`\`" "${HOME}/scripts/notify-job-failure.sh"

exit 1
fi
