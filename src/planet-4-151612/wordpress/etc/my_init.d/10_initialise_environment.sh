#!/usr/bin/env bash

# ==============================================================================
#
# Consolidate ENV variables, configure environment
# Must be sourced from each script which depends on these variables

ENV_FILE=/app/bin/env.sh

echo -e "#!/usr/bin/env sh\n# Generated file from /etc/my_init.d/10_initialise_environment" > $ENV_FILE

# shellcheck disable=SC2034
# echo "GEN_RANDOM='</dev/urandom tr -dc 'A-Za-z0-9!#% &()*+,-./:;<=>?@^_{|}~\" | head -c 64  ; echo'" >> $ENV_FILE

echo "export WP_DB_NAME=${WP_DB_NAME:-$MYSQL_DATABASE}" >> $ENV_FILE
echo "export WP_DB_USER=${WP_DB_USER:-$MYSQL_USER}" >> $ENV_FILE
echo "export WP_DB_PASS=${WP_DB_PASS:-$MYSQL_PASSWORD}" >> $ENV_FILE

echo "export WP_HOSTNAME=${WP_HOSTNAME:-${APP_HOSTNAME:-$DEFAULT_APP_HOSTNAME}}" >> $ENV_FILE
echo "export WP_SITE_URL=${WP_SITE_URL:-$WP_HOSTNAME}" >> $ENV_FILE
echo "export WP_SITE_HOME=${WP_SITE_HOME:-$WP_SITE_URL}" >> $ENV_FILE

echo "export WP_ADMIN_EMAIL=${WP_ADMIN_EMAIL:-$ADMIN_EMAIL}" >> $ENV_FILE

# Check if all key and salts are set, else use WP api to generate new strings
# Note: this resets user login sessions so advice is to set at container runtime

if [ -z "${WP_AUTH_KEY}" ] || \
   [ -z "${WP_SECURE_AUTH_KEY}" ] || \
   [ -z "${WP_LOGGED_IN_KEY}" ] || \
   [ -z "${WP_NONCE_KEY}" ] || \
   [ -z "${WP_AUTH_SALT}" ] || \
   [ -z "${WP_SECURE_AUTH_SALT}" ] || \
   [ -z "${WP_LOGGED_IN_SALT}" ] || \
   [ -z "${WP_NONCE_SALT}" ]; then
   _warning "Key or salt not set, generating new from https://api.wordpress.org/secret-key/1.1/salt/"
   KEYS=$(curl --connect-timeout 5 \
     --max-time 10 \
     --retry 5 \
     --retry-max-time 60 \
     https://api.wordpress.org/secret-key/1.1/salt/)

   WP_AUTH_KEY=$(echo $KEYS | sed -rn "s/.*define\('AUTH_KEY',\s+'([^']+).*/\1/p")
   WP_SECURE_AUTH_KEY=$(echo $KEYS | sed -rn "s/.*define\('SECURE_AUTH_KEY',\s+'([^']+).*/\1/p")
   WP_LOGGED_IN_KEY=$(echo $KEYS | sed -rn "s/.*define\('LOGGED_IN_KEY',\s+'([^']+).*/\1/p")
   WP_NONCE_KEY=$(echo $KEYS | sed -rn "s/.*define\('LOGGED_IN_KEY',\s+'([^']+).*/\1/p")

   WP_AUTH_SALT=$(echo $KEYS | sed -rn "s/.*define\('AUTH_SALT',\s+'([^']+).*/\1/p")
   WP_SECURE_AUTH_SALT=$(echo $KEYS | sed -rn "s/.*define\('SECURE_AUTH_SALT',\s+'([^']+).*/\1/p")
   WP_LOGGED_IN_SALT=$(echo $KEYS | sed -rn "s/.*define\('LOGGED_IN_SALT',\s+'([^']+).*/\1/p")
   WP_NONCE_SALT=$(echo $KEYS | sed -rn "s/.*define\('NONCE_SALT',\s+'([^']+).*/\1/p")
fi

# Key generation
echo "export WP_AUTH_KEY='${WP_AUTH_KEY}'" >> $ENV_FILE
echo "export WP_SECURE_AUTH_KEY='${WP_SECURE_AUTH_KEY}'" >> $ENV_FILE
echo "export WP_LOGGED_IN_KEY='${WP_LOGGED_IN_KEY}'" >> $ENV_FILE
echo "export WP_NONCE_KEY='${WP_NONCE_KEY}'" >> $ENV_FILE

# Salt generation
echo "export WP_AUTH_SALT='${WP_AUTH_SALT}'" >> $ENV_FILE
echo "export WP_SECURE_AUTH_SALT='${WP_SECURE_AUTH_SALT}'" >> $ENV_FILE
echo "export WP_LOGGED_IN_SALT='${WP_LOGGED_IN_SALT}'" >> $ENV_FILE
echo "export WP_NONCE_SALT='${WP_NONCE_SALT}'" >> $ENV_FILE

# # Propogate ENV vars to environment
# source $ENV_FILE
