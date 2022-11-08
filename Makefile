SHELL := /bin/bash
BUILD_FLAGS ?= -rp
BUILD_LIST ?=

DOCKER_BUILDKIT ?= 1

# ---

# Read default configuration
include config.default
export $(shell sed 's/=.*//' config.default)

# Read custom configuration if exist
ifneq ($(strip $(CONFIG)),)
include $(CONFIG)
export $(shell sed 's/=.*//' config.custom)
endif

# Pass TEST_FOLDERS env variable to limit which tests to run
TEST_FOLDERS ?=

# Check necessary commands exist

DOCKER := $(shell command -v docker 2> /dev/null)
SHELLCHECK := $(shell command -v shellcheck 2> /dev/null)
SHFMT := $(shell command -v shfmt 2> /dev/null)
YAMLLINT := $(shell command -v yamllint 2> /dev/null)

.DEFAULT_GOAL := all

all : build test
.PHONY : all

################################################################################

.PHONY: init
init: .git/hooks/pre-commit ignore

ignore:
	@git ls-files | grep -E "Dockerfile$$" | tr '\n' ' '| xargs git update-index --assume-unchanged
	@git ls-files | grep -E "README.md$$" | tr '\n' ' '| xargs git update-index --assume-unchanged

.git/hooks/%:
	@chmod 755 .githooks/*
	@find .git/hooks -type l -exec rm {} \;
	@find .githooks -type f -exec ln -sf ../../{} .git/hooks/ \;

################################################################################

format: format-sh

format-sh:
ifndef SHFMT
	$(error "shfmt is not installed: https://github.com/mvdan/sh")
endif
	@shfmt -i 2 -ci -w .

.PHONY : lint
lint: init
	@$(MAKE) -sj lint-docker lint-sh lint-yaml

lint-docker:
ifndef DOCKER
	$(error "docker is not installed: https://docs.docker.com/install/")
endif
	@find . -type f -name 'Dockerfile' -exec sh -c "cat {} | docker run --rm -i hadolint/hadolint" \;

lint-sh:
ifndef SHELLCHECK
	$(error "shellcheck is not installed: https://github.com/koalaman/shellcheck")
endif
ifndef SHFMT
	$(error "shfmt is not installed: https://github.com/mvdan/sh")
endif
	#@shfmt -f . | xargs shellcheck
	@shfmt -i 2 -ci -d .

lint-yaml:
ifndef YAMLLINT
	$(error "yamllint is not installed: https://github.com/adrienverge/yamllint")
endif
	@find . -type f -name '*.yml' | xargs yamllint
	@find . -type f -name '*.yaml' | xargs yamllint

################################################################################

.PHONY : clean
clean :
	bin/clean.sh

.PHONY : pull
pull :
	pushd bin >/dev/null; ./build.sh -p; popd > /dev/null

.PHONY : build
build : lint
	time bin/build.sh $(CONFIG) $(BUILD_FLAGS) $(BUILD_LIST)
	$(MAKE) ignore

.PHONY : test
test :
	TEST_FOLDERS=$(TEST_FOLDERS) time tests/test.sh $(CONFIG)
	$(MAKE) ignore

deploy:
	./bin/deploy.sh
