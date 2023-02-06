#! /usr/bin/env nix-shell
#! nix-shell -I nixpkgs=./. -i bash -p coreutils gnused nix nix-update
set -euo pipefail

DRV_DIR="$(dirname "${BASH_SOURCE[0]}")"

grab_version() {
  nix-instantiate --eval --strict -E "with import ./. {}; authelia.version" | tr -d '"'
}

fetch_html() {
  nix hash to-sri --type sha256 "$(nix-prefetch-url "https://github.com/authelia/authelia/releases/download/v${1}/authelia-v${1}-public_html.tar.gz")"
}

OLD_HTML_VERSION=$(grab_version)
OLD_HTML_SHA=$(fetch_html "${OLD_HTML_VERSION}")

nix-update authelia

NEW_HTML_VERSION=$(grab_version)
NEW_HTML_SHA=$(fetch_html "${NEW_HTML_VERSION}")

sed -i "s@sha256 = \"$OLD_HTML_SHA\";@sha256 = \"$NEW_HTML_SHA\";@" "$DRV_DIR/default.nix"
