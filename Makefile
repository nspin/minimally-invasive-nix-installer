remote := origin

.PHONY: copy
copy:
	rm -rf dist
	cp -rL --no-preserve=mode $$(nix-build release.nix -A installers.links) dist

.PHONY: deploy
deploy: tag := dist-$(shell cat dist/HASH)
deploy:
	git tag $(tag)
	git push $(remote) $(tag)
