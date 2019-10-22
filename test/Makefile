.PHONY: all build run

tag := mini-nix-test
store_path = $(shell nix-build . --no-out-link)

all: run

build: Dockerfile
	docker build -t $(tag) -f $< .

run: build
	docker run --mount type=bind,src=$(store_path),dst=/www,readonly -t $(tag)

runi: build
	docker run -it $(tag) /bin/bash
