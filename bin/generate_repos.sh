#!/bin/bash
set -eo pipefail

gcloud container images list --repository=gcr.io/planet-4-151612 --limit=2000 --format='get(name)' >bin/repo_list.txt
gcloud container images list --repository=gcr.io/planet4-production --limit=2000 --format='get(name)' >>bin/repo_list.txt
