#!/usr/bin/env bash
set -eo pipefail

# Yes, this expects a sibling directory to build. Make it so!
# eg https://github.com/greenpeace/planet4-gpi
SIBLING=${SIBLING:-planet4-gpi}

INFRA_VERSION=$(git rev-parse --abbrev-ref HEAD)

[[ -d "../planet4-base" ]] || echo "Warning: planet4-base directory not found. Please clone into sibling directory."

function beep() {
  [[ -x "beep.sh" ]] && beep.sh ${1:-1} .03
}

date

time (
  make clean
  make build ${1:+BUILD_FLAGS=${1}} ${2:+BUILD_LIST=${2}} || exit 1
  pushd "../${SIBLING}" >/dev/null 2>&1
  INFRA_VERSION="${INFRA_VERSION}" make || exit 1
  beep
  popd >/dev/null 2>&1
  make test
  beep 2
)
