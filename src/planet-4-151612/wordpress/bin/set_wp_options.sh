#!/usr/bin/env bash

optionlock="/app/source/public/.optionlock"

[[ -f $optionlock ]] && echo "$optionlock exists, not updating options." && exit 0

touch $optionlock

# Wordpress configuration startup
# FIXME Set blogdescription to something useful
_good "siteurl          ${WP_SITE_PROTOCOL}://${WP_SITE_URL:-$APP_HOSTNAME}"
_good "home             ${WP_SITE_PROTOCOL}://${WP_SITE_HOME:-$APP_HOSTNAME}"
_good "blogname         ${WP_TITLE}"
_good "blogdescription  ${WP_TITLE}"
_good "rewrite          ${WP_REWRITE_STRUCTURE}"

wp option set siteurl "${WP_SITE_PROTOCOL}://${WP_SITE_URL:-$APP_HOSTNAME}"
wp option set home "${WP_SITE_PROTOCOL}://${WP_SITE_HOME:-$APP_HOSTNAME}"
wp option set blogname "${WP_TITLE}"
wp option set blogdescription "${WP_TITLE}"
wp rewrite structure "${WP_REWRITE_STRUCTURE}"

# rm $optionlock
