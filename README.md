# Minimally-Invasive Nix Installer

This Nix installer works offline, and has no side-effects except for creating and populating `/nix`. The resulting installation is not meant to be used for host package management.

Simply run `install.sh` in the same directory as `mini-nix-*.tar.gz`. Note that `install.sh` verifies the integrity of `mini-nix-*.tar.gz`.
