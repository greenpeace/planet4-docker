# Greenpeace P4 Docker application
# Image: gcr.io/planet-4-151612/exim:v0.9.0
# Build: build-678
# Date:  Tue May 15 10:11:26 UTC 2018
# ------------------------------------------------------------------------
# DO NOT MAKE CHANGES HERE
# This file is built automatically from ./templates/Dockerfile.in
# ------------------------------------------------------------------------
  
FROM gcr.io/planet-4-151612/ubuntu:v0.9.0

MAINTAINER Raymond Walker <raymond.walker@greenpeace.org>

RUN apt-get update \
 && apt-get install -y --no-install-recommends exim4-daemon-light \
 && rm -Rf /tmp/* /var/tmp/* /var/lib/apt/lists/* \
 && rm -fr /usr/share/man/* /usr/share/doc/* /usr/share/locale/*

EXPOSE 25

COPY . /app

ENV \
  EXIM_ADMIN_EMAIL="raymond.walker@greenpeace.org" \
  EXIM_DELIVERY_MODE="smarthost" \
  EXIM_MAIL_FROM="greenpeace.org" \
  EXIM_SMARTHOST_AUTH_PASSWORD="" \
  EXIM_SMARTHOST_AUTH_USERNAME="" \
  EXIM_SMARTHOST="smtp-relay.gmail.com::587"
