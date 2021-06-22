# Minimally-Invasive Nix Installer

This Nix installer has no side-effects other than populating `/nix`, which must already exist as an empty directory with mode `0755`. The resulting installation is not meant to be used for host package management. The installer script is short and easy to audit.

## Usage

```sh
sudo install -d -m 0755 -o $USER /nix
curl -L https://github.com/nspin/minimally-invasive-nix-installer/raw/master/dist/install.sh | bash
```

Next, add the following (or similar) to your shell initialization:

```sh
export PATH="/nix/env/bin:$PATH"
export MANPATH="/nix/env/share/man:$MANPATH"
export NIX_SSL_CERT_FILE=/nix/env/etc/ssl/certs/ca-bundle.crt # or your favorite cert bundle
```

You may want to create `/etc/nix/nix.conf`.

To uninstall, simply `chmod -R u+w /nix && rm -r /nix`.
