set -e

url=https://raw.githubusercontent.com/nspin/minimally-invasive-nix-installer/dist/install.sh

sudo install -d -m 0755 -o 1000 /nix
curl $url | bash
