# Docker builds for Planet4 on Google Container Registry

## Description

This is a work in progress at creating a modular, re-usable Docker application architecture for the Greenpeace Planet 4 Wordpress application project.

# Quickstart

```
./build.sh -r
```

This triggers a remote build using the settings from `config.default`

## Building locally versus remotely
```
# Build the Docker platform suite on your local machine
./build.sh -l

# Build the Docker platform suite on gcr.io
./build.sh -r
```

## Updating build configuration variables

To rewrite platform variables without triggering a build, run `build.sh` without the `-l` or `-r` command line arguments:

```
./build.sh
```

This rewrites local Dockerfile ENV variables such as `NGINX_VERSION` or `OPENSSL_VERSION`, but will not trigger a complete rebuild. Since this repository is monitored for commit changes, simply updating these variables and pushing the commit will submit a new build request automagically.

## Customising the container build

See config.default for optional build configuration parameters. The easiest way to overwrite default parameters is to add new entries to a bash key value file, eg `config.custom`, then re-run the build with command line parameter like so: `./build.sh -c config.custom`

Note: to overwrite the default values, use the short form of the variable without the leading `DEFAULT_`. For example, to change the docker container tag version, use `BUILD_TAG`, not `DEFAULT_BUILD_TAG`. The reason this approach was taken was to ensure hierarchical resolution of variables from multiple sources:

### Variable resolution priority
1.  Config file custom values
2.  Environment variables
3.  Config file default values

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
