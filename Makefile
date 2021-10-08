remote := origin
nix-build := nix-build release.nix -A installers.links

.PHONY: build
build:
	$(nix-build)

.PHONY: copy
copy:
	rm -rf dist
	cp -rL --no-preserve=mode $$($(nix-build)) dist

.PHONY: deploy
deploy: tag := dist-$(shell cat dist/VERSION)
deploy:
	git tag $(tag)
	git push $(remote) $(tag)
