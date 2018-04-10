#!/usr/bin/env bash
set -ex

[[ "$WP_BAKE" = "true" ]] || exit 0

rm -fr /app/source/public
composer_exec="composer --profile -vv"
$composer_exec download:wordpress

$composer_exec reset:themes
$composer_exec reset:plugins

$composer_exec copy:health-check

$composer_exec copy:themes
$composer_exec copy:assets
$composer_exec copy:plugins

$composer_exec core:style

$composer_exec core:js

$composer_exec core:js-minify

$composer_exec site:custom

ln -s /app/source/public /app/www

generate_wp_config.sh

echo "Files baked, returning status 1 to exit container."
echo "You'll see an error which can be happily ignored."
# Don't panic!
exit 1
