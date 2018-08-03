SHELL := /bin/bash
BUILD_FLAGS ?= -rp
BUILD_LIST ?=

ifneq ($(strip $(CONFIG)),)
CONFIG := -c $(CONFIG)
endif

TEST_FOLDERS ?=

.DEFAULT_GOAL := all

all : clean build test
.PHONY : all

.PHONY : clean
clean :
		bin/clean.sh

.PHONY : pull
pull :
		pushd bin >/dev/null; ./build.sh -p; popd > /dev/null

.PHONY : build
build :
		bin/build.sh $(CONFIG) $(BUILD_FLAGS) $(BUILD_LIST) || exit 1

.PHONY : test
test :
		TEST_FOLDERS=$(TEST_FOLDERS) tests/test.sh $(CONFIG)

deploy:
	  ./bin/deploy.sh
