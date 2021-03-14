# OpenResty + Pagespeed + OpenSSL

![OpenResty 1.13.6.2](https://img.shields.io/badge/openresty-1.13.6.2-brightgreen.svg) ![ngx_pagespeed latest-stable](https://img.shields.io/badge/ngx_pagespeed-latest--stable-brightgreen.svg) ![OpenSSL 1.0.2o](https://img.shields.io/badge/OpenSSL-1.0.2o-brightgreen.svg)

Built on [gcr.io/planet-4-151612/ubuntu](https://registry.hub.docker.com/u/greenpeace/ubuntu/), a lightly modified Ubuntu Xenial [Phusion Base Image](https://phusion.github.io/baseimage-docker/).

```bash
docker run -v "/path/to/www:/app/source/public" -p "80:80" -p "443:443"  gcr.io/planet-4-151612/openresty:develop
```

Files are served from `/app/source/public/`, SSL certificates are generated in `/etc/nginx/ssl`, `/etc/nginx/sites-enabled/*` is searched for virtual hosts.

Nginx is configured with sane security defaults for out-of-the-box webservice, highly configurable by environment variables and is compiled from mainline source.

## Service configuration via ENV

Nginx is configurable via environment variables, which are re-applied to the configuration on service start, so you can adjust server parameters at container start with:

```bash
docker run -e "UPLOAD_MAX_SIZE=42M" gcr.io/planet-4-151612/openresty
```

A minimal docker-compose.yml file:

```yml
version: '2'
services:
  app:
   image: gcr.io/planet-4-151612/openresty
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /path/to/www:/app/source/public
```

### Variables

variable                   | default | description
-------------------------- | ------- | ------------------------------------------------------------------------------------
APP_USER                   | nginx   | Service user name
APP_GROUP                  | nginx   | Service group name
UPLOAD_MAX_SIZE            | ${UPLOAD_MAX_SIZE}     | Sets `nginx_client_max_body_size`
OPENRESTY_MAX_WORKER_PROCESSES | ${OPENRESTY_MAX_WORKER_PROCESSES}       | Sets `worker_processes`, will not exceed number of logical cores
CHOWN_APP_DIR              | false   | If true `chown` `/app/source/public` as `APP_USER:APP_GROUP`

## Security

OpenResty is compiled from mainline source according to Ubuntu configuration and compile flags, with the following modifications:

- OpenSSL v1.0.2o from source - <https://www.openssl.org/source/>
- Google Pagespeed nginx latest stable from source - <https://github.com/pagespeed/ngx_pagespeed/releases>
- The `http_autoindex_module` disabled

HTTPS2 is configured using modern sane defaults, including

- Mozilla's intermediate profile - see <https://wiki.mozilla.org/Security/Server_Side_TLS>
- SSLv2 and SSLv3 are disabled, TLSv1 TLSv2 and TLSv3 are enabled
- Automatic generation of a 2048bit Diffie-Helman parameter file if one is not provided
- Self-signed SSL certificates are generated on first container start, and stored in `/etc/nginx/ssl/default.key` `/etc/nginx/ssl/default.crt`. To install your own certificates I recommend bind-mounting `ssl` and `sites-enabled` folders.
- @todo LetsEncrypt!

## On service start

- nginx user is set to `${APP_USER}` (default is nginx)
- creates user and group from `{APP_USER}`, some sanity checks for matching UID / GID in the event that user/group already exists
- if `${CHOWN_APP_DIR} /app/source/public` (default false)
- `worker_processes` is set to the number of available processor cores and adjusts `/etc/nginx/nginx.conf` to match, up to a maximum number of cores `${OPENRESTY_MAX_WORKER_PROCESSES}`
- `client_max_body_size` is set to `${UPLOAD_MAX_SIZE}`
