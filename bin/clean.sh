#!/usr/bin/env bash
set -e

# ----------------------------------------------------------------------------

# Find real file path of current script
# https://stackoverflow.com/questions/59895/getting-the-source-directory-of-a-bash-script-from-within

source="${BASH_SOURCE[0]}"
while [[ -h "$source" ]]
do # resolve $source until the file is no longer a symlink
  dir="$( cd -P "$( dirname "$source" )" && pwd )"
  source="$(readlink "$source")"
  [[ $source != /* ]] && source="$dir/$source" # if $source was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
GIT_ROOT_DIR="$( cd -P "$( dirname "$source" )/.." && pwd )"

find "${GIT_ROOT_DIR}/src" -name "Dockerfile" -exec rm -r "{}" \;
find "${GIT_ROOT_DIR}/tests/src" -name "Dockerfile" -exec rm -r "{}" \;
# find "${GIT_ROOT_DIR}/src" -name "README.md" -exec rm -r "{}" \;
