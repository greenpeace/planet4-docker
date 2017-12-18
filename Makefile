BUILD_FLAGS?=-rp
BUILD_LIST?=

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
		pushd bin >/dev/null; ./build.sh $(BUILD_FLAGS) $(BUILD_LIST); popd >/dev/null

.PHONY : test
test :
		tests/test.sh
