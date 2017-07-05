FROM php:7.1-fpm-alpine

ENV PLANET4_BASE_URL https://github.com/greenpeace/planet4-base
ENV DBUSER planet4
ENV DBPASS planet4
ENV DBNAME planet4
ENV DBHOST mysql

RUN apk --update add \
  git mysql-client rsync nginx subversion && \
  docker-php-ext-install mysqli && \
  curl -L -o /tmp/redis.tar.gz https://github.com/phpredis/phpredis/archive/3.1.2.tar.gz \
  tar xfz /tmp/redis.tar.gz \
  rm -r /tmp/redis.tar.gz \
  mv phpredis-3.1.2 /usr/src/php/ext/redis \
  docker-php-ext-install redis \
  rm /tmp/redis.tar.gz \
  curl -sS https://getcomposer.org/installer | php && \
  mv composer.phar /usr/bin/composer && \
  chown nginx:nginx /var/www/html

USER nginx
WORKDIR /var/www/html
RUN git clone $PLANET4_BASE_URL /var/www/html && \
  cp wp-cli.yml.default wp-cli.yml && \
  composer install

USER root
COPY conf/nginx/nginx.conf /etc/nginx/nginx.conf
COPY conf/nginx/site.conf /etc/nginx/conf.d/site.conf
COPY bin/entrypoint.sh /entrypoint.sh
COPY conf/php/php.ini /usr/local/etc/php-fpm.d/php_session.conf

CMD [ "/entrypoint.sh" ]
