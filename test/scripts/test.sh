set -e

. env.sh

nix --version
nix-store -q --tree $(realpath $(which nix)) | cat
nix-store --gc --print-roots

nix-build test-expressions/ -A hello
./result/bin/hello
