remote := origin
tag := $(shell cat dist/TAG)

.PHONY: copy
copy:
	rm -rf dist
	cp -rL --no-preserve=mode $$(nix-build release.nix -A links) dist

.PHONY: deploy
deploy:
	git tag $(tag)
	git push $(remote) $(tag)
