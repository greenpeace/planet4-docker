BUILD_FLAGS?=-rp
BUILD_LIST?=

.DEFAULT_GOAL := all

all : build test
.PHONY : all

.PHONY : test
test :
		tests/test.sh

.PHONY : build
build :
		pushd bin; ./build.sh $(BUILD_FLAGS) $(BUILD_LIST); popd
