#!/usr/bin/env bash
set -eao pipefail

# Wordpress environment variable consolidation
if \
    [ -z "${WP_AUTH_KEY}" ] || \
    [ -z "${WP_AUTH_SALT}" ] || \
    [ -z "${WP_LOGGED_IN_KEY}" ] || \
    [ -z "${WP_LOGGED_IN_SALT}" ] || \
    [ -z "${WP_NONCE_KEY}" ] || \
    [ -z "${WP_NONCE_SALT}" ] || \
    [ -z "${WP_SECURE_AUTH_KEY}" ] || \
    [ -z "${WP_SECURE_AUTH_SALT}" ]
 then
   _warning "Key or salt not set, generating new from https://api.wordpress.org/secret-key/1.1/salt/"
   KEYS=$(curl --connect-timeout 5 \
     --max-time 10 \
     --retry 5 \
     --retry-max-time 60 \
     https://api.wordpress.org/secret-key/1.1/salt/)

   WP_AUTH_KEY="$(echo "$KEYS" | sed -rn "s/.*define\('AUTH_KEY',\s+'([^']+).*/\1/p")"
   WP_SECURE_AUTH_KEY="$(echo "$KEYS" | sed -rn "s/.*define\('SECURE_AUTH_KEY',\s+'([^']+).*/\1/p")"
   WP_LOGGED_IN_KEY="$(echo "$KEYS" | sed -rn "s/.*define\('LOGGED_IN_KEY',\s+'([^']+).*/\1/p")"
   WP_NONCE_KEY="$(echo "$KEYS" | sed -rn "s/.*define\('LOGGED_IN_KEY',\s+'([^']+).*/\1/p")"

   WP_AUTH_SALT="$(echo "$KEYS" | sed -rn "s/.*define\('AUTH_SALT',\s+'([^']+).*/\1/p")"
   WP_SECURE_AUTH_SALT="$(echo "$KEYS" | sed -rn "s/.*define\('SECURE_AUTH_SALT',\s+'([^']+).*/\1/p")"
   WP_LOGGED_IN_SALT="$(echo "$KEYS" | sed -rn "s/.*define\('LOGGED_IN_SALT',\s+'([^']+).*/\1/p")"
   WP_NONCE_SALT="$(echo "$KEYS" | sed -rn "s/.*define\('NONCE_SALT',\s+'([^']+).*/\1/p")"

   # Key generation
   export WP_AUTH_KEY
   export WP_AUTH_SALT
   export WP_LOGGED_IN_KEY
   export WP_LOGGED_IN_SALT
   export WP_NONCE_KEY
   export WP_NONCE_SALT
   export WP_SECURE_AUTH_KEY
   export WP_SECURE_AUTH_SALT
fi
