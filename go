#!/usr/bin/env bash

# Yes, this expects planet4-base to be a sibling directory. Make it so!
# https://github.com/greenpeace/planet4-base

time ( make clean; \
  make build ${1:+BUILD_FLAGS=${1}} ${2:+BUILD_LIST=${2}}; \
  pushd "../planet4-base"; \
  make build; \
  beep.sh; \
  popd; \
  make test;
  beep.sh -r 3 \
)
