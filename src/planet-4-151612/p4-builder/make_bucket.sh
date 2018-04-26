#!/usr/bin/env bash
set -exu

gsutil mb gs://${WP_STATELESS_BUCKET}

gsutil iam ch allUsers:objectViewer gs://${WP_STATELESS_BUCKET}

gsutil iam ch serviceAccount:${WP_STATELESS_OWNER}:admin gs://${WP_STATELESS_BUCKET}
