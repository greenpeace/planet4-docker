#!/bin/bash

# Copyright © 2017 Google Inc.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Google Container Registry Garbage Collection
# Source: https://gist.github.com/27Bslash6/ba9dca6ca6b90c05d6bfa9136c667e9a
# Forked by Raymond Walker <raymond.walker@greenpeace.org>
# Original by Ahmet Alp Balkan https://gist.github.com/ahmetb

IFS=$'\n\t'
set -eo pipefail

if [[ "$#" -ne 2 || "${1}" == '-h' || "${1}" == '--help' ]]
then
  cat >&2 <<"EOF"

$(basename "$0") cleans up tagged or untagged images pushed before specified date
for a given repository (an image name without a tag/digest).

USAGE:
  gcrgc.sh REPOSITORY DATE

EXAMPLE
  gcrgc.sh gcr.io/greenpeace/php-fpm 2017-04-01

  would clean up everything under the gcr.io/greenpeace/php-fpm repository
  pushed before 2017-04-01.

TRIAL RUN
  Setting the environment variable will display a list of all images that would
  be deleted.

  TRIAL_RUN=1 gcrgc.sh gcr.io/greenpeace/php-fpm 2017-04-01

  Would list all image digests that would be deleted.
EOF
  exit 1
elif [[ ! "${2}" =~ [0-9]{4}-[0-9]{2}-[0-9]{2} ]]
then
  echo "wrong DATE format; use YYYY-MM-DD." >&2
  exit 1
fi

if  [[ ! -z "${TRIAL_RUN}" ]] && \
    [[ "${TRIAL_RUN}" != 'false' ]] && \
    [[ ${TRIAL_RUN} -ne 0 ]]
then
  TRIAL_RUN=1
  echo >&2 "Trial run only, no changes will be committed"
fi

main() {
  local C=0
  IMAGE="${1}"
  DATE="${2}"
  for digest in $(gcloud container images list-tags "${IMAGE}" --limit=999999 --sort-by=TIMESTAMP \
    --filter="timestamp.datetime < '${DATE}'" --format='get(digest)')
  do
    (

      if [[ ${TRIAL_RUN} ]]
      then
        echo "gcloud container images delete -q --force-delete-tags ${IMAGE}@${digest}"
      else
        set -x
        gcloud container images delete -q --force-delete-tags "${IMAGE}@${digest}"
      fi

    )
    let C=C+1
  done
  echo "Deleted ${C} images in ${IMAGE}." >&2
}

main "${1}" "${2}"
