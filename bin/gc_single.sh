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
# set -x

if [[ "$#" -lt 1 || "${1}" == '-h' || "${1}" == '--help' ]]; then
  cat >&2 <<"EOF"

gc_single.sh generates a list of deletion commands for a single repository that are older than a certain date (or by default 6 months)

It will, regardless of age, preserve the most recently pushed image, the most recent image with the tag 'latest'
and all images that are tagged with a semver version.

USAGE:
  gc_single.sh REPOSITORY DATE
  gc_single.sh REPOSITORY

EXAMPLE
  gc_single.sh gcr.io/greenpeace/php-fpm 2017-04-01

  would clean up everything under the gcr.io/greenpeace/php-fpm repository
  pushed before 2017-04-01.

  By default if DATE is omitted then it will be set to a date two months ago from today.

TRIAL RUN
  Setting the environment variable will display a list of all images instead of generating a file with the commands.

  TRIAL_RUN=1 gc_single.sh gcr.io/greenpeace/php-fpm 2017-04-01
EOF
  exit 1
elif [[ ! "${2}" =~ ([0-9]{4}-[0-9]{2}-[0-9]{2}|^$) ]]; then
  echo "wrong DATE format; use YYYY-MM-DD." >&2
  exit 1
fi

if [[ -n "${TRIAL_RUN}" ]] &&
  [[ "${TRIAL_RUN}" != 'false' ]] &&
  [[ ${TRIAL_RUN} -ne 0 ]]; then
  TRIAL_RUN=1
  echo >&2 "Trial run only, no changes will be committed"
fi

main() {
  IMAGE="${1}"
  two_months_ago=$(($(date "+%s") - 5184000))
  two_months_ago_format=$(date -d "@$two_months_ago" "+%F")

  DATE="${2:-$two_months_ago_format}"
  # init vars
  latest=''
  save=()
  last=''
  deletions=()
  arr=()
  C=0
  echo "Querying GCR for current images for $IMAGE"
  echo "Preparing to delete images created before $DATE"
  for image in $(gcloud container images list-tags "${IMAGE}" --limit=999999 --sort-by=~TIMESTAMP \
    --filter="timestamp.datetime < '${DATE}'" --format=json | jq -r -c '.[]'); do

    digest=$(echo "$image" | jq -j '.digest')
    deletions+=("$digest")

    for tag in $(echo "$image" | jq -r -c '.tags[]'); do
      if [[ "$tag" == 'latest' && "$latest" == '' ]]; then
        latest="$digest"
      elif [[ $tag =~ [0-9]+\.[0-9]+\.[0-9]+ && ${#save[@]} -le 10 ]]; then
        save+=("$digest")
      elif [[ $tag =~ v[0-9]+\.[0-9]+\.[0-9]+ && ${#save[@]} -le 10 ]]; then
        save+=("$digest")
      elif [[ $tag =~ v[0-9]+\.[0-9]+ && ${#save[@]} -le 10 ]]; then
        save+=("$digest")
      elif [ "$last" == '' ]; then
        last=$digest
      else
        :
      fi
    done
  done

  save+=("$latest" "$last")
  # shellcheck disable=SC2207
  arr=($({ printf '%s\n' "${deletions[@]}" "${save[@]}"; } | sort | uniq -u))

  for digest in "${arr[@]}"; do
    if [[ ${TRIAL_RUN} ]]; then
      echo "gcloud container images delete -q --force-delete-tags ${IMAGE}@${digest}"
    else
      echo "gcloud container images delete -q --force-delete-tags ${IMAGE}@${digest}" >>command_list.txt
    fi
    _=$((C++))
  done
  echo "Added ${C} images in ${IMAGE} to command_list.txt." >&2
}

main "${1}" "${2}"
echo "" >>command_list.txt
