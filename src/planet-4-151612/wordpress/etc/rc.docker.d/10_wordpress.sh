#!/usr/bin/env bash
set -e

[[ ${WP_SET_OPTIONS_ON_BOOT} == "true" ]] && /app/bin/set_wp_options.sh

/app/bin/generate_wp_config.sh
