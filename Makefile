SHELL := /bin/bash
BUILD_FLAGS ?= -rp
BUILD_LIST ?=

ifneq ($(strip $(CONFIG)),)
CONFIG := -c $(CONFIG)
endif

MICROSCANNER_TOKEN ?= $(shell cat MICROSCANNER_TOKEN)
export MICROSCANNER_TOKEN

# Pass TEST_FOLDERS env variable to limit which tests to run
TEST_FOLDERS ?=

# Check necessary commands exist

CIRCLECI := $(shell command -v circleci 2> /dev/null)
DOCKER := $(shell command -v docker 2> /dev/null)
SHELLCHECK := $(shell command -v shellcheck 2> /dev/null)
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

.PHONY : lint
lint: init
	@$(MAKE) -sj lint-docker lint-sh lint-yaml lint-ci

lint-docker:
ifndef DOCKER
	$(error "docker is not installed: https://docs.docker.com/install/")
endif
# 	for d in $(shell find . -type f -name 'Dockerfile') ; do \
# 		docker run --rm -i hadolint/hadolint < $$d ; \
# 	done

lint-sh:
ifndef SHELLCHECK
	$(error "shellcheck is not installed: https://github.com/koalaman/shellcheck")
endif
# 	@find . -type f -name '*.sh' | xargs shellcheck

lint-yaml:
ifndef YAMLLINT
	$(error "yamllint is not installed: https://github.com/adrienverge/yamllint")
endif
	@find . -type f -name '*.yml' | xargs yamllint
	@find . -type f -name '*.yaml' | xargs yamllint

lint-ci:
ifndef CIRCLECI
	$(error "circleci is not installed: https://circleci.com/docs/2.0/local-cli/#installation")
endif
	@circleci config validate >/dev/null

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
