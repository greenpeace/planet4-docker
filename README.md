# Docker builds for Planet 4

![Planet4](./planet4.png)

## Description

This is a work in progress at creating a modular, re-usable Docker application architecture for the Greenpeace Planet 4 Wordpress application project.

# Quickstart

```bash
./bin/build.sh -rp
# or via Make
make
```

This triggers a Google Container Registry (GCR) build using the settings from `config.default` and pulls the resultant images.

## Building locally versus remotely

```bash
# Build the Docker platform suite on your local machine
./bin/build.sh -l

# Build the Docker platform suite on gcr.io
./bin/build.sh -r
```

```bash
# Perform a remote build, pull new images once complete, and show verbose build output
./bin/build.sh -r -p -v
# or
./bin/build.sh -rpv
```

## Subset builds
Build order can be specified on a per-project basis by the inclusion of a `build_order` file in the root of that project.
This is helpful in determining the correct build order for local or partial builds where projects have dependencies on parent images.
Subset builds can significantly speed up container rebuilds if changes are made late in the dependency list.

There are two different methods of specifying a subset build - providing a list of images to build, or by providing a starting point and appending `+` to the starting image which will build that image and any following it in the build order.

For example, with a given `build_order` file such as:

```bash
ubuntu
openresty
php-fpm
wordpress
p4-onbuild
```

1. Specifically stating which containers to build:

```bash
# Perform a remote build of a small subset
./bin/build.sh -r openresty wordpress
```

In this example, only the openresty and wordpress images are built.

2. Building the dependency chain from a given start point:

```bash
# Performs a remote build of all images in the build_order file, starting at php-fpm:
./bin/build.sh -r php-fpm+
```

In this example, the `php-fpm wordpress p4-onbuild` images are all built due to the trailing `+` on php-fpm


## Updating build configuration variables

Containers can be modified at build time by build arguments `ARG`, or on container start with environment variables `ENV`.

To build containers with custom values, or to specify different default values, you can supply build-time command line arguments (see below) or make edits to a configuration file.

To rewrite platform variables without triggering a build, run `build.sh` without the `-l` or `-r` command line arguments:

```bash
./bin/build.sh
```

This will update the local Dockerfile ENV variables such as `OPENRESTY_VERSION`, but does not send a GCR build request. Since this repository is monitored for commit changes, simply updating these variables and pushing the commit will submit a new build request automagically in the CI pipeline.

## Customising the container build

See `config.default` for optional build configuration parameters. The easiest way to overwrite default parameters is to add new entries to a bash key value file, eg `config.custom`, then re-run the build with command line parameter like so: `./bin/build.sh -c config.custom`

Also note that not all defined variables are configurable on container start, for example changing `OPENRESTY_VERSION` won't have any effect at container start as it's a variable used to install the infrastructure instead of control application behaviour.

### Variable resolution priority
1.  Config file custom values (optional)
2.  Environment variables (optional)
3.  Config file default values

### Specify build time parameters from a configuration file:

```bash
echo "GOOGLE_PROJECT_ID=greenpeace-testing" >> config.custom
./bin/build -c config.custom
```

### Using environment variables

```bash
# Build the whole docker suite on GCB:
./bin/build.sh -r

# Build only a subset of the project, with a custom source branch,
# starting from wordpress and continuing down the dependency chain
GIT_REF=feature/example ./bin/build.sh -r wordpress+
```

## Cleaning old images

A garbage collection script `gcrgc.sh` is available which can automatically delete old images in Google Container Regsitry.

### Trial run

You can test which images it would delete, without performing any changes to the registry, by setting the envionrment varible `TRIAL_RUN` to any truthy value, eg:

```bash
TRIAL_RUN=true ./bin/gc.sh gcr.io/planet-4-151612/ubuntu 2017-10-01
```

### Delete all ubuntu images in the planet-4-151612 project older than 1st October 2017

```bash
./bin/gc.sh gcr.io/planet-4-151612/ubuntu 2017-10-01
```

### Iterate over all images in a build order, deleting older than 1st March 2017

```bash
for i in $(cat src/planet-4-151612/build_order)
do
  ./bin/gc.sh gcr.io/planet-4-151612/${i} 2017-04-01
done
```
