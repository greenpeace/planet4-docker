#!/usr/bin/env bash
set -exo pipefail

# If the build url isn't set, we're building locally so
if [[ -z "${CIRCLE_BUILD_URL}" ]]
then
  # Don't attempt to update the repository
  echo "Local build, skipping repository update..."
  exit 0
fi

if [[ -z "${CIRCLE_BRANCH}" ]] && [[ "${CIRCLE_TAG}" ]]
then
  # Find the branch associated with this commit
  # Why is this so hard, CircleCI?
  git remote update
  # Find which remote branch contains the current commit
  CIRCLE_BRANCH=$(git branch -r --contains ${CIRCLE_SHA1} | grep -v 'HEAD' | awk '{split($1,a,"/"); print a[2]}')
  # Checkout that branch / tag
  git checkout ${CIRCLE_BRANCH}
  if [[ "$(git rev-parse HEAD)" != "${CIRCLE_SHA1}" ]]
  then
    >&2 echo "Found the wrong commit!"
    >&2 echo "Wanted: ${CIRCLE_SHA1}"
    >&2 echo "Got:    $(git rev-parse HEAD)"
    >&2 echo "Not updating build details in repository, continuing ..."
    exit 0
  fi
fi
echo "${CIRCLE_BRANCH}" > /tmp/workspace/var/circle-branch-name
export CIRCLE_BRANCH

# Build without arguments to update Dockerfile from template
./build.sh

# Configure git user
git config user.email "circleci-bot@greenpeace.org"
git config user.name "CircleCI Bot"
git config push.default simple
# Add changes
git add .
# Get previous commit message and append a message, skipping CI
OLD_MSG=$(git log --format=%B -n1)
git commit -m "$OLD_MSG" -m "Update build numbers [skip ci]"
# Push the updated Dockerfile and README to the repo
git push --force-with-lease --set-upstream origin ${CIRCLE_BRANCH}
