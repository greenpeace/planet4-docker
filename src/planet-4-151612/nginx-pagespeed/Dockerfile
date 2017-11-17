# Greenpeace P4 Docker application
# Image: gcr.io/planet-4-151612/nginx-pagespeed:develop
# Build: build-246
# Date:  Fri Nov 17 04:51:05 UTC 2017
# ------------------------------------------------------------------------
# DO NOT MAKE CHANGES HERE
# This file is built automatically from ./templates/Dockerfile.in
# ------------------------------------------------------------------------

FROM gcr.io/planet-4-151612/ubuntu:develop

MAINTAINER Raymond Walker <raymond.walker@greenpeace.org>

EXPOSE 80
EXPOSE 443

ENV APP_GROUP="nginx" \
    APP_USER="nginx" \
    HEADERS_MORE_VERSION="0.33" \
    NGINX_PAGESPEED_VERSION="latest" \
    NGINX_PAGESPEED_RELEASE="stable" \
    NGINX_VERSION="1.13.6" \
    OPENSSL_VERSION="1.1.0g"

COPY . /app/

RUN set -x && \
    chmod 755 /app/bin/*.sh && \
    useradd -r -s /usr/sbin/nologin "${APP_USER}" && \
    mkdir -p /var/log/nginx /var/cache/nginx && \
    wget --retry-connrefused --waitretry=1 -t 5 --progress=bar -O - "https://www.openssl.org/source/openssl-1.1.0g.tar.gz" | tar xzf - -C /tmp && \
    wget --retry-connrefused --waitretry=1 -t 5 --progress=bar -O - "https://nginx.org/download/nginx-1.13.6.tar.gz" | tar zxf - -C /tmp && \
    wget --retry-connrefused --waitretry=1 -t 5 --progress=bar -O - "https://github.com/openresty/headers-more-nginx-module/archive/v0.33.tar.gz" | tar zxf - -C /tmp && \
    wget --retry-connrefused --waitretry=1 -t 5 --progress=bar -O - "https://github.com/pagespeed/ngx_pagespeed/archive/latest-stable.tar.gz" | tar zxf - -C /tmp && \
    PSOL_URL="$(cat "/tmp/ngx_pagespeed-latest-stable/PSOL_BINARY_URL")" && \
    if [ "$(uname -m)" = x86_64 ]; then PSOL_BIT_SIZE_NAME="x64"; else PSOL_BIT_SIZE_NAME="ia32"; fi && \
    wget --retry-connrefused --waitretry=1 -t 5 --progress=bar -O - "$(echo $PSOL_URL | sed "s/\$BIT_SIZE_NAME/$PSOL_BIT_SIZE_NAME/g")" | tar zxf - -C "/tmp/ngx_pagespeed-latest-stable" && \
    apt-get update && \
  	apt-get -y --no-install-recommends install \
      autoconf \
      automake \
      build-essential \
      git-core \
      libgd2-xpm-dev \
      libgeoip-dev \
      libgoogle-perftools-dev \
      libpcre3-dev \
      libperl-dev \
      libtool \
      libxml2-dev \
      libxslt1-dev \
      zlib1g-dev \
      && \
  	cd "/tmp/nginx-1.13.6" && \
  	./configure \
  		--prefix=/etc/nginx  \
  		--sbin-path=/usr/sbin/nginx  \
  		--conf-path=/etc/nginx/nginx.conf  \
  		--error-log-path=/var/log/nginx/error.log \
  		--http-log-path=/var/log/nginx/access.log \
  		--pid-path=/var/run/nginx.pid \
  		--lock-path=/var/run/nginx.lock \
  		--http-client-body-temp-path=/var/cache/nginx/client_temp \
  		--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
  		--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp  \
  		--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp  \
  		--http-scgi-temp-path=/var/cache/nginx/scgi_temp  \
  		--user="${APP_USER}"  \
  		--group="${APP_USER}"  \
  		--with-http_ssl_module  \
  		--with-http_realip_module  \
  		--with-http_addition_module  \
  		--with-http_sub_module  \
  		--with-http_dav_module  \
  		--with-http_flv_module  \
  		--with-http_mp4_module  \
  		--with-http_gunzip_module  \
  		--with-http_gzip_static_module  \
  		--with-http_random_index_module  \
  		--with-http_secure_link_module \
  		--with-http_stub_status_module  \
  		--with-http_auth_request_module  \
  		--without-http_autoindex_module \
  		--without-http_ssi_module \
  		--with-threads  \
  		--with-stream  \
  		--with-stream_ssl_module  \
  		--with-mail  \
  		--with-mail_ssl_module  \
  		--with-file-aio  \
  		--with-http_v2_module \
  		--with-cc-opt='-g -O2 -fstack-protector --param=ssp-buffer-size=4 -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2'  \
  		--with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,--as-needed' \
  		--with-ipv6 \
  		--with-pcre-jit \
  		--with-openssl=/tmp/openssl-1.1.0g \
      --add-module=/tmp/headers-more-nginx-module-0.33 \
  		--add-module=/tmp/ngx_pagespeed-latest-stable  && \
  	make && \
  	make install && \
  	apt-get purge -yqq automake autoconf libtool git-core build-essential zlib1g-dev libpcre3-dev libxslt1-dev libxml2-dev libgd2-xpm-dev libgeoip-dev libgoogle-perftools-dev libperl-dev && \
  	apt-get autoremove -yqq && \
  	apt-get clean && \
  	rm -Rf /tmp/* /var/tmp/* /var/lib/apt/lists/* && \
    mkdir -p /etc/nginx/ssl /app/www && \
    echo "$(nginx -V 2>&1)" > /app/www/index.html

ENV CLOUDFLARE_ENABLED="false" \
    DEFAULT_CHOWN_APP_DIR="false" \
    DEFAULT_NGINX_FASTCGI_BACKEND="php-fpm:9000" \
    DEFAULT_NGINX_KEEPALIVE_TIMEOUT="30" \
    DEFAULT_NGINX_MAX_WORKER_PROCESSES="8" \
    DEFAULT_NGINX_SENDFILE="on" \
    DEFAULT_PAGESPEED_DISABLE_FILTERS="" \
    DEFAULT_PAGESPEED_REBEACON_KEY="uwuudeL7iedoo7Meengi" \
    DEFAULT_PAGESPEED_REWRITE_LEVEL="CoreFilters" \
    DEFAULT_UPLOAD_MAX_SIZE="50M" \
    PAGESPEED_ENABLED="true" \
    PHP_ENABLED="false" \
    SSL_ENABLED="false"
