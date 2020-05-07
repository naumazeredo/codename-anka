EXEC=anka

.PHONY: build

all: build run

build-unix:
	@echo [Building on Unix]
	./build.sh $(EXEC)

build-win:
	@echo [Building on Windows]
	call build.bat

build:
ifeq ($(OS),Windows_NT)
	make build-win
else
	make build-unix
endif


run:
	./build/$(EXEC)

