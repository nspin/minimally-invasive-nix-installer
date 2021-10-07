set -e

arch=$(uname -m)
url=https://github.com/nspin/minimally-invasive-nix-installer/raw/master/dist/install-$arch-linux.sh

sudo install -d -m 0755 -o 1000 /nix
curl -L $url | bash
