# docker-ubuntu-base

https://registry.hub.docker.com/u/greenpeace/ubuntu/

Automated daily build of an Ubuntu Xenial base image from phusion/baseimage (https://github.com/phusion/baseimage-docker/blob/master/Changelog.md#0919-release-date-2016-07-08).

- Modified apt sources.list to use `http://mirror.rackspace.com/ubuntu/`, which seems reliable, fast and local to most servers
- Container timezone is set via environment variable `UTC`, defaults to `Australia/Sydney`
