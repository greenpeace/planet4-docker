# Greenpeace P4 Docker application
# Image: gcr.io/planet-4-151612/ubuntu:develop
# Build: build-834
# Date:  Sat Jun  9 05:36:16 UTC 2018
# ------------------------------------------------------------------------
# DO NOT MAKE CHANGES HERE
# This file is built automatically from ./templates/Dockerfile.in
# ------------------------------------------------------------------------
  
FROM phusion/baseimage:0.10.1 as base

LABEL authors="Raymond Walker <raymond.walker@greenpeace.org>"

COPY . /app/

ARG MICROSCANNER_TOKEN

ENV MICROSCANNER_TOKEN="${MICROSCANNER_TOKEN}"

# ADD https://get.aquasec.com/microscanner .

RUN rm -fr /etc/apt/sources.list && \
    ln -s /app/sources.list /etc/apt/sources.list && \
    apt-get update && \
    apt-get -y upgrade && \
    apt-get install --no-install-recommends -y wget tzdata && \
    rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* && \
    chmod 755 /app/bin/* && \
    ln -s /app/bin/set_timezone.sh /etc/my_init.d/00_set_timezone.sh && \
    wget https://github.com/jwilder/dockerize/releases/download/v0.6.1/dockerize-linux-amd64-v0.6.1.tar.gz && \
    tar -C /app/bin -xzvf dockerize-linux-amd64-v0.6.1.tar.gz && \
    rm dockerize-linux-amd64-v0.6.1.tar.gz && \
    rm -fr /usr/share/man/* /usr/share/doc/*

# RUN ./microscanner "${MICROSCANNER_TOKEN}"

FROM scratch

COPY --from=base / /

# Local time zone of application container
ENV \
    APP_ENV="production" \
    APP_GID="1000" \
    APP_GROUP="app" \
    APP_HOSTNAME="example.com" \
    APP_UID="1000" \
    APP_USER="app" \
    CONTAINER_TIMEZONE="UTC" \
    DEBIAN_FRONTEND="noninteractive" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US:en" \
    LC_ALL="en_US.UTF-8" \
    MICROSCANNER_TOKEN="" \
    PATH="/app/bin:$PATH"

WORKDIR /app

ENTRYPOINT ["/app/bin/entrypoint.sh"]

CMD ["/sbin/my_init"]
