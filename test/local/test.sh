set -e

url=http://localhost:8000/install.sh

(cd /www && python3 -m http.server --bind localhost) &
sleep 3

sudo install -d -m 0755 -o 1000 /nix
curl $url | bash

export PATH="/nix/env/bin:${PATH}"
export MANPATH="/nix/env/share/man:${MANPATH}"
export NIX_SSL_CERT_FILE=/nix/env/etc/ssl/certs/ca-bundle.crt

nix --version
nix-store -q --tree $(realpath $(which nix)) | cat
nix-store --gc --print-roots
