#!/usr/bin/env bash
set -exu

# Create bucket if it doesn't exist
gsutil ls "gs://${WP_STATELESS_BUCKET}" || gsutil mb "gs://${WP_STATELESS_BUCKET}"

gsutil iam ch allUsers:objectViewer "gs://${WP_STATELESS_BUCKET}"

gsutil iam ch "serviceAccount:${WP_STATELESS_OWNER}:admin" "gs://${WP_STATELESS_BUCKET}"

gsutil -m setmeta -r -h "Cache-Control:public, max-age=2678400" "gs://${WP_STATELESS_BUCKET}"
