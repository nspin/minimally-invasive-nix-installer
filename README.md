# Minimally-Invasive Nix Installer

```
$ sudo install -d -m 0755 -o $USER /nix
$ curl https://raw.githubusercontent.com/nspin/minimally-invasive-nix-installer/dist/install.sh | bash
```

This Nix installer has no side-effects other than populating `/nix`, which must already exist as an empty directory with mode 0755.

The resulting installation is not meant to be used for host package management.

The installer script is short and easy to audit.
