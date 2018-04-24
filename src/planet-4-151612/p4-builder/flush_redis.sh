#!/usr/bin/env bash

set -eu

echo "Sleeping 180s for deployment to stabilise..."
sleep 180
redis=$(kubectl get pods --namespace ${HELM_NAMESPACE} -l "app=${HELM_RELEASE}-redis" -o jsonpath="{.items[0].metadata.name}")
echo "Flushing redis pod ${redis}..."
kubectl --namespace ${HELM_NAMESPACE} exec $redis redis-cli flushdb
