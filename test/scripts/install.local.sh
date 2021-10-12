set -e

url=http://localhost:8000/install-min-nix.fragment.sh

(cd /www && python3 -m http.server --bind localhost) &
sleep 3

sudo install -d -m 0755 -o 1000 /nix
curl -fL $url | bash
