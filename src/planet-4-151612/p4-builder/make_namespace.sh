#!/usr/bin/env bash
set -exu

dockerize \
  -template templates/namespace.yaml.tmpl:namespace.yaml

cat namespace.yaml

if kubectl get ns "${HELM_NAMESPACE}"
then
  echo "Namespace ${HELM_NAMESPACE} already exists..."
  exit 0
fi

echo "Creating namespace ${HELM_NAMESPACE}..."
kubectl create -f namespace.yaml
