#!/usr/bin/env bash

# Yes, this expects planet4-base to be a sibling directory. Make it so!
# https://github.com/greenpeace/planet4-base

time ( make clean & \
  make build ${1:+BUILD_FLAGS=${1}} ${2:+BUILD_LIST=${2}} && \
  pushd "../planet4-base" >/dev/null 2>&1 && \
  make build && \
  beep.sh 1 .03 && \
  popd >/dev/null 2>&1 && \
  make test && \
  beep.sh 2 .03 && \
  wait
)
