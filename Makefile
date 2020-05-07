EXEC=anka

.PHONY: build

all: build run

build-unix:
	@echo "building on unix ... "
	./build.sh $(EXEC)

build-win:
	@echo "building on windows ..."
	call build.bat

build:
ifeq ($(OS),Windows_NT)
	make build-win
else
	make build-unix
endif


run:
	./build/$(EXEC)

