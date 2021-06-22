.PHONY: all build run

base_tag := mini-nix-test
local_tag := $(base_tag)-local
remote_tag := $(base_tag)-remote
label := min-nix-test

here = $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
nixpkgs_path = $(here)/../nixpkgs
store_path = $(shell nix-build local-installer.nix --no-out-link -A testBundle)

mount_nixpkgs = --mount type=bind,src=$(nixpkgs_path),dst=/nixpkgs,readonly
mount_www = --mount type=bind,src=$(store_path),dst=/www,readonly

all: local-run

local-build:
	docker build -t $(local_tag) --build-arg install_location=local --label $(label) .

remote-build:
	docker build -t $(remote_tag) --build-arg install_location=remote --label $(label) .

local-run: local-build
	docker run --rm $(mount_nixpkgs) $(mount_www) -t $(local_tag)

remote-run: remote-build
	docker run --rm $(mount_nixpkgs) -t $(remote_tag)

local-runi: local-build
	docker run --rm $(mount_nixpkgs) $(mount_www) -it $(local_tag) /bin/bash

remote-runi: remote-build
	docker run --rm $(mount_nixpkgs) -it $(remote_tag) /bin/bash

.PHONY:
clean:
	for id in $$(docker ps -aq -f "label=$(label)"); do \
		docker rm -f $$id; \
	done
