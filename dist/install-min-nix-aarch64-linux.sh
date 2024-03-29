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

check_dest() {
    if [ -z "$UID" ]; then
        die "\$UID is not set."
    fi

    log "Checking for empty '$dest' with uid='$UID' mode='0755'..."

    if [ ! -e "$dest" ]; then
        log "'$dest' does not exist. Please create it (e.g. with 'sudo install -d -m 0755 -o $UID $dest') and re-run this script."
        exit 1
    fi

    dest_mode_and_uid="$(stat -c "%f %u" "$dest")"
    if [ "$dest_mode_and_uid" != "41ed $UID" ]; then # 040755
        die "'$dest' is not a directory with uid='$UID' and mode='0755'."
    fi
    if [ -n "$(ls "$dest")" ]; then
        die "'$dest' is not empty."
    fi
}

require_util date
require_util curl
require_util sha256sum
require_util tar

tarball_url=https://github.com/nspin/minimally-invasive-nix-installer/raw/dist-h6yr5xax7m/dist/min-nix-2.5.1-aarch64-linux.tar.gz
tarball_sha256=abdf8438d90430aad9e0a1cfd8c3227a2c0d6ed643819b525514835ec0aa629a
archive_name=min-nix-2.5.1-aarch64-linux
env_store_path=/nix/store/3w23bwz7dhbn9sazdlcr7zizsgyjsz8h-min-nix-env-2.5.1

dest=/nix

check_dest

tarball_path="${TMPDIR:-/tmp}/$archive_name-$(date +%s).tar.gz"
log "Fetching '$tarball_url' to '$tarball_path'..."
trap "{ rm -f $tarball_path; }" EXIT
curl -fL -o "$tarball_path" "$tarball_url"

log "Verifying the integrity of '$tarball_path'..."
observed_sha256="$(sha256sum "$tarball_path" | cut -c 1-64)"
if [ "$tarball_sha256" != "$observed_sha256" ]; then
    die "SHA-256 hash mismatch for '$tarball_path': expected $tarball_sha256, got $observed_sha256."
fi

log "Unpacking '$tarball_path' into '$dest'..."
tar -xz -f $tarball_path -C $dest --strip 1 --delay-directory-restore
chmod u+w $dest/store

log "Initializing Nix database..."
$env_store_path/bin/nix-store --init
$env_store_path/bin/nix-store --load-db < $dest/reginfo
rm -f $dest/reginfo

log "Establishing Nix environment..."
$env_store_path/bin/nix-store --realise --add-root $dest/env --indirect $env_store_path > /dev/null

log
log "SUCCESS"
log
log "To uninstall, simply remove '/nix'."
log "You may want to create '/etc/nix/nix.conf'."
log "Add the following to your shell init:"
log
log "   export PATH=\"$dest/env/bin:\$PATH\""
log "   export MANPATH=\"$dest/env/share/man:\$MANPATH\""
log "   export NIX_SSL_CERT_FILE=$dest/env/etc/ssl/certs/ca-bundle.crt # or your favorite cert bundle"
log

}
