#!/usr/bin/env bash
set -eo pipefail

# Yes, this expects planet4-base to be a sibling directory. Make it so!
# https://github.com/greenpeace/planet4-base

function beep() {
  [[ -x "beep.sh" ]] && beep.sh ${1:-1} .03
}

time ( make clean & \
  make build ${1:+BUILD_FLAGS=${1}} ${2:+BUILD_LIST=${2}} && \
  pushd "../planet4-base" >/dev/null 2>&1 && \
  make build && \
  beep && \
  popd >/dev/null 2>&1 && \
  make test && \
  beep 2 && \
  wait
)
date
