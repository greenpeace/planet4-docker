#!/usr/bin/env bash
set -exu

# Exit if bucket exists, doing nothing
gsutil ls gs://${WP_STATELESS_BUCKET} && exit 0

gsutil mb gs://${WP_STATELESS_BUCKET}

gsutil iam ch allUsers:objectViewer gs://${WP_STATELESS_BUCKET}

gsutil iam ch serviceAccount:${WP_STATELESS_OWNER}:admin gs://${WP_STATELESS_BUCKET}
