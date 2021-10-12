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
script_url="https://github.com/nspin/minimally-invasive-nix-installer/raw/dist-fbfgaw5wkw/dist/install-${arch}-linux.sh"

case "$arch" in
    aarch64) script_sha256=d2e91e4d0ff05aa50b6806e9166450da893d2f22918af39394e365f8bdc9bb5f ;;
    x86_64) script_sha256=baf2761b9c7b2a7c42bb90c1d29bff3ea42a86c0f61385b2a8a6bb23ce2e5693 ;;

    *)
        echo >&2 "unsupported architecture: '$arch'"
        exit 1
        ;;
esac

script_path="${TMPDIR:-/tmp}/$script_name-$(date +%s).tar.gz"
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
