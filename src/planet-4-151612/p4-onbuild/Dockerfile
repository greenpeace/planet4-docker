# Greenpeace P4 Docker application
# Image: gcr.io/planet-4-151612/p4-onbuild:develop
# Build: build-252
# Date:  Sun Nov 19 12:13:51 UTC 2017
# ------------------------------------------------------------------------
# DO NOT MAKE CHANGES HERE
# This file is built automatically from ./templates/Dockerfile.in
# ------------------------------------------------------------------------

FROM gcr.io/planet-4-151612/wordpress:develop

MAINTAINER Raymond Walker <raymond.walker@greenpeace.org>

COPY . /app/

RUN apt-get update && apt-get install -y subversion && \
    apt-get clean && \
    mkdir -p /app/source && \
    rm -Rf /tmp/* /var/tmp/* /var/lib/apt/lists/*

ONBUILD ARG GIT_SOURCE="https://github.com/greenpeace/planet4-base"
ONBUILD ARG GIT_REF="develop"
ONBUILD ARG COMPOSER="composer.json"
ONBUILD ARG GITHUB_OAUTH_TOKEN

ONBUILD ENV GIT_SOURCE "${GIT_SOURCE}"
ONBUILD ENV GIT_REF "${GIT_REF}"
ONBUILD ENV COMPOSER "${COMPOSER}"
ONBUILD ENV GITHUB_OAUTH_TOKEN "${GITHUB_OAUTH_TOKEN}"

ONBUILD RUN git clone --branch "${GIT_REF}" "${GIT_SOURCE}" /app/source

ONBUILD WORKDIR /app/source

ONBUILD RUN \
  /app/bin/composer.phar --profile -vv config --global github-oauth.github.com ${GITHUB_OAUTH_TOKEN} && \
  /app/bin/composer.phar --profile -vv install --no-interaction && \
  /app/bin/composer.phar clear-cache && \
  cp wp-cli.yml.default wp-cli.yml && \
  rm -fr /app/www
