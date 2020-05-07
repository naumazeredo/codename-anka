EXEC=anka

.PHONY: build

all: build run

build-osx:
	@echo "building on osx / linux ... "
	./scripts/build_osx.sh $(EXEC)

build-win:
	@echo "building on windows ..."
	./build.bat

build:
ifeq ($(OS),Windows_NT)
	make build-win
else
	make build-osx
endif


run:
	./build/$(EXEC)

