.PHONY: all build run

base_tag := mini-nix-test
local_tag := $(base_tag)-local
remote_tag := $(base_tag)-remote

store_path = $(shell nix-build local --no-out-link)

all: local-run

local-build:
	docker build -t $(local_tag) local

remote-build:
	docker build -t $(remote_tag) remote

local-run: local-build
	docker run --mount type=bind,src=$(store_path),dst=/www,readonly -t $(local_tag)

remote-run: remote-build
	docker run -t $(remote_tag)

local-runi: local-build
	docker run -it $(local_tag) /bin/bash

remote-runi: remote-build
	docker run -it $(remote_tag) /bin/bash
