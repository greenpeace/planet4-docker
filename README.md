# Docker builds for Planet4 on Google Container Registry

## Description

This is a work in progress at creating a modular, re-usable Docker application architecture for the Greenpeace Planet 4 Wordpress application project.

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
