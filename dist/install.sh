{ # Prevent execution if this script was only partially downloaded

set -Eeuo pipefail

script_name=@script_name@

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

script_name="install-${arch}-linux.sh"
script_url="https://github.com/nspin/minimally-invasive-nix-installer/raw/dist-69sdm5r2yf/dist/install-${arch}-linux.sh"

case "$arch" in
    aarch64) script_sha256=182bdd77fe78ae78319bdb4793e20faddccd108500b558335eca40132cae67ce ;;
    x86_64) script_sha256=950fe448b4d697d80e52b946080abb4f63d2c3208c31aed95cc3b74a46215a35 ;;

    *)
        echo >&2 "unsupported architecture: '$arch'"
        exit 1
        ;;
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
