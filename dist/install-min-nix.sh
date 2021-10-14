{ # Prevent execution if this script was only partially downloaded

set -Eeuo pipefail

log() {
    echo "$0:" "$@" >&2
}

die() {
    log "FAILURE: $1"
    exit 1
}

require_util() {
    type "$1" > /dev/null 2>&1 || command -v "$1" > /dev/null 2>&1 || \
        die "This script requires '$1', which could not be found."
}

require_util date
require_util curl
require_util sha256sum
require_util uname
require_util bash

arch="$(uname -m)"

script_name="install-min-nix-${arch}-linux.sh"
script_url="https://github.com/nspin/minimally-invasive-nix-installer/raw/dist-y64jgzkzg5/dist/install-min-nix-${arch}-linux.sh"

case "$arch" in
    aarch64) script_sha256=16502703601d784b5830c8994c953ba83761fc7cba61ed3294a636a830e738a8 ;;
    x86_64) script_sha256=afb6fa2641763cba6ae2d35a309c34ef1dc382b6b0aaf6486cd0aa494e6acf62 ;;

    *) die "unsupported architecture: '$arch'" ;;
esac

script_path="${TMPDIR:-/tmp}/$(date +%s)-$script_name"
log "Fetching '$script_url' to '$script_path'..."
trap "{ rm -f $script_path; }" EXIT
curl -fL -o "$script_path" "$script_url"

log "Verifying the integrity of '$script_path'..."
observed_sha256="$(sha256sum "$script_path" | cut -c 1-64)"
if [ "$script_sha256" != "$observed_sha256" ]; then
    die "SHA-256 hash mismatch for '$script_path': expected $script_sha256, got $observed_sha256."
fi

bash $script_path

}
