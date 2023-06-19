#!/usr/bin/env bash
set -eo pipefail

# Description: Installs openresty from source with prerequisites
#  - OpenSSL

if [[ "${OPENRESTY_SOURCE}" = "apt" ]]; then
  # import our GPG key:
  wget -qO - https://openresty.org/package/pubkey.gpg | apt-key add -

  # for installing the add-apt-repository command
  # (you can remove this package and its dependencies later):
  apt-get -y install software-properties-common

  # add the our official APT repository:
  add-apt-repository -y "deb http://openresty.org/package/ubuntu $(lsb_release -sc) main"
fi

apt-get update

if [[ "${OPENRESTY_SOURCE}" = "apt" ]]; then
  apt-get -y --no-install-recommends install openresty
else
  apt-get -y --no-install-recommends install \
    autoconf \
    automake \
    build-essential \
    libmaxminddb-dev \
    libgd-dev \
    libgoogle-perftools-dev \
    libpcre3-dev \
    libperl-dev \
    libssl-dev \
    libtool \
    libxml2-dev \
    libxslt1-dev \
    uuid-dev \
    zlib1g-dev \
    ;
  wget -nv --retry-connrefused -t 5 -O - "https://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz" | tar zxf - -C /tmp
  procs=$(cat /proc/cpuinfo | grep processor | wc -l)
  mkdir -p /var/log/nginx /var/cache/nginx
  wait

  cd "/tmp/openresty-${OPENRESTY_VERSION}" || exit 1
  ./configure \
    -j${procs} \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --http-client-body-temp-path=/var/cache/nginx/client_temp \
    --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
    --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
    --user="${APP_USER}" \
    --group="${APP_USER}" \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_mp4_module \
    --with-http_realip_module \
    --with-http_secure_link_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_sub_module \
    --without-http_autoindex_module \
    --without-http_encrypted_session_module \
    --with-threads \
    --with-stream \
    --with-stream_ssl_module \
    --with-mail \
    --with-mail_ssl_module \
    --with-file-aio \
    --with-http_v2_module \
    --with-cc-opt='-g -O2 -fstack-protector-strong --param=ssp-buffer-size=4 -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2' \
    --with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,--as-needed' \
    --with-ipv6 \
    --with-pcre-jit \
    --with-debug
  make -j${procs} install
  apt-get purge -yqq \
    autoconf \
    automake \
    build-essential \
    libgd-dev \
    libgoogle-perftools-dev \
    libpcre3-dev \
    libperl-dev \
    libtool \
    libxml2-dev \
    libxslt1-dev \
    zlib1g-dev
fi

apt-get autoremove -yqq

[[ -x "/usr/sbin/nginx" ]] || exit 1

nginx -V
