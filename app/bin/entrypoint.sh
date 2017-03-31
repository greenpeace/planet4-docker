#!/bin/sh

su -m -c "sed -i s:db_user:$DBUSER: /var/www/html/wp-cli.yml" -ls /bin/sh nginx &&
su -m -c "sed -i s:db_pass:$DBPASS: /var/www/html/wp-cli.yml" -ls /bin/sh nginx &&
su -m -c "sed -i s:wordpress:$DBNAME: /var/www/html/wp-cli.yml" -ls /bin/sh nginx &&
su -m -c "sed -i s:127.0.0.1:$DBHOST: /var/www/html/wp-cli.yml" -ls /bin/sh nginx &&
su -m -c "cd /var/www/html && composer run-script site-install" -ls /bin/sh nginx &&

php-fpm &
nginx -g "daemon off;"
