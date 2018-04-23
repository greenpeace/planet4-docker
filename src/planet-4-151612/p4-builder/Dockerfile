# Greenpeace P4 Docker application
# Image: gcr.io/planet-4-151612/p4-builder:develop
# Build: build-499
# Date:  Mon Apr 23 01:42:53 UTC 2018
# ------------------------------------------------------------------------
# DO NOT MAKE CHANGES HERE
# This file is built automatically from ./templates/Dockerfile.in
# ------------------------------------------------------------------------
  
FROM gcr.io/planet-4-151612/circleci-base:latest

LABEL authors="Raymond Walker <raymond.walker@greenpeace.org>"

COPY --chown=circleci:circleci . /home/circleci/

RUN chmod 755 /home/circleci/*.sh
