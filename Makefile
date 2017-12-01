BUILD_FLAGS?=-rp
BUILD_LIST?=

.DEFAULT_GOAL := all

all : clean build test
.PHONY : all

.PHONY : clean
clean :
		bin/clean.sh

.PHONY : build
build :
		pushd bin; ./build.sh $(BUILD_FLAGS) $(BUILD_LIST); popd

.PHONY : test
test :
		tests/test.sh
