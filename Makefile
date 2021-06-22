remote := origin
get_tag := $$(cat dist/TAG)

.PHONY:
copy:
	store_path=$$(nix-build release.nix -A links) \
		&& rm -rf dist \
		&& cp -rL --no-preserve=mode $$store_path dist

.PHONY:
deploy:
	git tag $(get_tag)
	git push $(remote) $(get_tag)
