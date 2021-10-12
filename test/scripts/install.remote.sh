set -e

url=https://github.com/nspin/minimally-invasive-nix-installer/raw/master/dist/install-min-nix.fragment.sh

sudo install -d -m 0755 -o 1000 /nix
curl -fL $url | bash
