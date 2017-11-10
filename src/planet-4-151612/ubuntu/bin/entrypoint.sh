#!/usr/bin/env bash
set -euo pipefail

# Configure environment
for env_file in /app/env/*
do
  # shellcheck source=/dev/null
  . ${env_file}
done

# Add application user
/app/bin/add_user.sh

# =============================================================================
# 	BOOT
# =============================================================================

_good "$(date) - " "exec $*"

# Default Docker CMD will be /sbin/my_init
if [[ "$1" = "/sbin/my_init" ]]
then
  shift
	exec /sbin/my_init "$@"
else
  # Execute the custom CMD
	exec /bin/sh -c "$@"
fi
