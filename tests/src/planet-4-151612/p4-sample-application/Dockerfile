FROM gcr.io/planet-4-151612/wordpress:develop

ENV \
  APP_HOSTNAME="test.planet4.dev" \
  GIT_SOURCE="https://github.com/greenpeace/planet4-base" \
  GIT_REF="master" \
  WP_TITLE="GPI - Testing Site"

RUN cd .. && \
  git clone "https://github.com/greenpeace/planet4-base" source && \
  cd source && \
  git checkout "master" && \
  /app/bin/composer.phar --profile -vv install && \
  /app/bin/composer.phar clearcache
