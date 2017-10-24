# Greenpeace P4 Docker application
# Build: build-104
# ------------------------------------------------------------------------
# DO NOT MAKE CHANGES HERE
# This file is built automatically from ./templates/Dockerfile.in
# ------------------------------------------------------------------------

FROM phusion/baseimage:0.9.22
MAINTAINER Ray Walker <raymond.walker@greenpeace.org>

# Tell the container there is no tty
ENV DEBIAN_FRONTEND noninteractive

# Local time zone of application container
ENV DEFAULT_CONTAINER_TIMEZONE UTC

# Automatic choose local mirror for sources list
COPY sources.list /etc/apt/sources.list

COPY . /app

# Update to latest packages and tidy up
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get install --no-install-recommends -y tzdata && \
    rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* && \
    chmod +x /app/bin/* && \
    if [ ! -f "/etc/my_init.d/00_set_timezone.sh" ]; then ln -s /app/bin/set_timezone.sh /etc/my_init.d/00_set_timezone.sh; fi
