#!/usr/bin/env bash
set -ex

[[ "$WP_BAKE" = "true" ]] || exit 0

rm -fr /app/source/public

composer --profile -vv download:wordpress

composer --profile -vv reset:themes
composer --profile -vv reset:plugins

composer --profile -vv copy:health-check

composer --profile -vv copy:themes
composer --profile -vv copy:assets
composer --profile -vv copy:plugins

composer --profile -vv core:style

echo "Files baked, running away!"

# Don't panic!
exit 1
