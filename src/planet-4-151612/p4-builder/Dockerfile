# Greenpeace P4 Docker application
# Image: gcr.io/planet-4-151612/p4-builder:v0.7.3
# Build: build-562
# Date:  Thu Apr 26 06:44:27 UTC 2018
# ------------------------------------------------------------------------
# DO NOT MAKE CHANGES HERE
# This file is built automatically from ./templates/Dockerfile.in
# ------------------------------------------------------------------------
  
FROM gcr.io/planet-4-151612/circleci-base:latest

LABEL authors="Raymond Walker <raymond.walker@greenpeace.org>"

COPY --chown=circleci:circleci . /home/circleci/

RUN chmod 755 /home/circleci/*.sh && \
    helm init --client-only && \
    helm repo add p4-helm-charts https://p4-helm-charts.storage.googleapis.com
