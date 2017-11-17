# Testing-SLEUOkQOh9wz
# Image: gcr.io/planet-4-151612/ubuntu:develop
# Build: build-244
# Date:  Fri Nov 17 00:37:06 UTC 2017
# ------------------------------------------------------------------------
# DO NOT MAKE CHANGES HERE
# This file is built automatically from ./templates/Dockerfile.in
# ------------------------------------------------------------------------

FROM phusion/baseimage:test-wulOFntnak3m as base

MAINTAINER Raymond Walker <raymond.walker@greenpeace.org>

COPY . /app/

RUN rm -fr /etc/apt/sources.list && \
    ln -s /app/sources.list /etc/apt/sources.list && \
    apt-get update && \
    apt-get -y upgrade && \
    apt-get install --no-install-recommends -y wget tzdata && \
    rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* && \
    chmod 755 /app/bin/* && \
    ln -s /app/bin/set_timezone.sh /etc/my_init.d/00_set_timezone.sh && \
    wget https://github.com/jwilder/dockerize/releases/download/vtest-D0eODsbkR9kU/dockerize-linux-amd64-vtest-D0eODsbkR9kU.tar.gz && \
    tar -C /app/bin -xzvf dockerize-linux-amd64-vtest-D0eODsbkR9kU.tar.gz && \
    rm dockerize-linux-amd64-vtest-D0eODsbkR9kU.tar.gz && \
    rm -fr /usr/share/man/* /usr/share/doc/* /usr/share/locale/*

FROM scratch

COPY --from=base / /

# Local time zone of application container
ENV DEBIAN_FRONTEND="noninteractive" \
    DEFAULT_APP_ENV="production" \
    DEFAULT_APP_GID="1000" \
    DEFAULT_APP_GROUP="app" \
    DEFAULT_APP_HOSTNAME="example.com" \
    DEFAULT_APP_UID="1000" \
    DEFAULT_APP_USER="app" \
    DEFAULT_CONTAINER_TIMEZONE="Australia/Hobart" \
    PATH="/app/bin:$PATH"

WORKDIR /app

ENTRYPOINT ["/app/bin/entrypoint.sh"]

CMD ["/sbin/my_init"]
