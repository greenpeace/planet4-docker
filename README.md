# Docker builds for Planet4 on Google Container Registry

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/8c54834e6f1a4f3e864b5f8614347c01?branch=0-1-0)](https://www.codacy.com/app/Greenpeace/planet4-docker?utm_source=github.com&utm_medium=referral&utm_content=greenpeace/planet4-docker&utm_campaign=badger) [![CircleCI](https://circleci.com/gh/greenpeace/planet4-docker/tree/0-1-0.svg?style=shield)](https://circleci.com/gh/greenpeace/planet4-docker/tree/0-1-0)


## Description

This is a work in progress at creating a modular, re-usable Docker application architecture for the Greenpeace Planet 4 Wordpress application project.

# Quickstart

```
./build.sh -r
```

This triggers a Google Container Registry (GCR) build using the settings from `config.default`

## Building locally versus remotely
```
# Build the Docker platform suite on your local machine
./build.sh -l

# Build the Docker platform suite on gcr.io
./build.sh -r
```

```
# Perform a remote build, pull new images once complete, and show verbose build output
./build.sh -r -p -v
# or
./build.sh -rpv
```

## Updating build configuration variables

Containers can be modified at build time by build arguments `ARG`, or on container start with environment variables `ENV`.

To build containers with custom values, or to specify different default values, you can supply build-time command line arguments (see below) or make edits to a configuration file.

To rewrite platform variables without triggering a build, run `build.sh` without the `-l` or `-r` command line arguments:

```
./build.sh
```

This will update the local Dockerfile ENV variables such as `NGINX_VERSION` or `OPENSSL_VERSION`, but does not send a GCR build request. Since this repository is monitored for commit changes, simply updating these variables and pushing the commit will submit a new build request automagically in the CI pipeline.

## Customising the container build

See `config.default` for optional build configuration parameters. The easiest way to overwrite default parameters is to add new entries to a bash key value file, eg `config.custom`, then re-run the build with command line parameter like so: `./build.sh -c config.custom`

Note: to overwrite the default values, it's recommended to edit the short form of the variable without the leading `DEFAULT_`. For example, to change the application repository branch, use `GIT_REF`, not `DEFAULT_GIT_REF`. This ensures hierarchical resolution of variables from multiple sources, and enables the values to be configured at build and runtime, while falling back to sane default values.

Also note that not all defined variables are configurable on container start, for example changing `NGINX_VERSION` won't have any effect at container start as it's a variable used to install the infrastructure instead of control application behaviour.

### Variable resolution priority
1.  Config file custom values (optional)
2.  Environment variables (optional)
3.  Config file default values

Another valid use-case is to supply custom default values by editing, eg the `DEFAULT_MAX_UPLOAD_SIZE` and still allow runtime configuration by modifying the environment on container start.

### Specify build time parameters from a configuration file:
```
echo "GOOGLE_PROJECT_ID=greenpeace-testing" >> config.custom
./build -c config.custom

```
### Using environment variables
```
# Build the whole docker suite:
./build.sh

# Build the resultant sites:
./build.sh site

# Build a custom project from custom git tag:
GOOGLE_PROJECT_ID=greenpeace-testing REV_TAG=20171222 ./build.sh site
```
