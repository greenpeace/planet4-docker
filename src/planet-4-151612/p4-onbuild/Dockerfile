# Greenpeace P4 Docker application
# Image: gcr.io/planet-4-151612/p4-onbuild:feature-php
# Build: build-228
# Date:  Mon Nov 13 10:25:07 UTC 2017
# ------------------------------------------------------------------------
# DO NOT MAKE CHANGES HERE
# This file is built automatically from ./templates/Dockerfile.in
# ------------------------------------------------------------------------

FROM gcr.io/planet-4-151612/wordpress:feature-php

MAINTAINER Raymond Walker <raymond.walker@greenpeace.org>

COPY . /app/

WORKDIR /app

RUN apt-get update && apt-get install -y subversion && \
    apt-get clean && \
    rm -Rf /tmp/* /var/tmp/* /var/lib/apt/lists/*

ONBUILD ARG GIT_SOURCE="https://github.com/greenpeace/planet4-base"
ONBUILD ARG GIT_REF="develop"
ONBUILD ARG COMPOSER="composer.json"
ONBUILD ARG GITHUB_OAUTH_TOKEN

ONBUILD ENV GIT_SOURCE "${GIT_SOURCE}"
ONBUILD ENV GIT_REF "${GIT_REF}"
ONBUILD ENV COMPOSER "${COMPOSER}"
ONBUILD ENV GITHUB_OAUTH_TOKEN "${GITHUB_OAUTH_TOKEN}"

ONBUILD RUN /app/bin/add_user.sh && \
  mkdir -p "${COMPOSER_HOME}" && \
  git clone --branch "${GIT_REF}" "${GIT_SOURCE}" /app/source

ONBUILD WORKDIR /app/source

ONBUILD RUN chown -R "${APP_USER:-$DEFAULT_APP_USER}:${APP_GROUP:-$DEFAULT_APP_GROUP}" "${COMPOSER_HOME}" /app/source && \
  echo "Installing composer dependencies with ${COMPOSER}" && \
  composer --profile -vvv config --global github-oauth.github.com ${GITHUB_OAUTH_TOKEN} && \
  composer --profile -vvv install --no-interaction && \
  cp wp-cli.yml.default wp-cli.yml && \
  rm -fr /app/www
