#!/usr/bin/env bash

set -eu

redis=$(kubectl get pods --namespace "${HELM_NAMESPACE}" -l "app=${HELM_RELEASE}-redis" -o jsonpath="{.items[0].metadata.name}")
echo "Flushing redis pod ${redis} in ${HELM_NAMESPACE}..."
kubectl --namespace "${HELM_NAMESPACE}" exec "$redis" redis-cli flushdb
