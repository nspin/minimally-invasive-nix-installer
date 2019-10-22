.PHONY: all build run

tag := mini-nix-test
store_path = $(shell nix-build ../release.nix -A bundle --no-out-link)

all: run

build: Dockerfile
	docker build -t $(tag) -f $< $(store_path)

run: build
	docker run -t $(tag)

runi: build
	docker run -it $(tag) /bin/bash
