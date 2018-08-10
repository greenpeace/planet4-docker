#!/usr/bin/env bash

optionlock="${PUBLIC_PATH}/.optionlock"

if [[ -f "$optionlock" ]]
then
   _warning "$optionlock exists, will not set wp options..."
   exit 0
fi

touch "$optionlock"

# Wordpress configuration startup
# FIXME Set blogdescription to something useful
# _good "siteurl          ${WP_SITE_PROTOCOL}://${WP_SITE_URL:-$APP_HOSTNAME}"
# _good "home             ${WP_SITE_PROTOCOL}://${WP_SITE_HOME:-${WP_SITE_URL:-WP_SITE_URL}}"
# _good "blogname         ${WP_TITLE}"
# _good "blogdescription  ${WP_DESCRIPTION}"
_good "rewrite          ${WP_REWRITE_STRUCTURE}"

# wp option set siteurl         "${WP_SITE_PROTOCOL}://${WP_SITE_URL:-$APP_HOSTNAME}"
# wp option set home            "${WP_SITE_PROTOCOL}://${WP_SITE_HOME:-${WP_SITE_URL:-WP_SITE_URL}}"
# wp option set blogname        "${WP_TITLE}"
# wp option set blogdescription "${WP_TITLE}"
wp rewrite structure          "${WP_REWRITE_STRUCTURE}"
