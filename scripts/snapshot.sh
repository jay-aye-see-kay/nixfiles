#!/bin/sh
# Snapshot tests for this flake.
#
# Premise: a Nix derivation hash is a perfect summary of every input that went
# into building it. If `.drv` paths are unchanged after a refactor, the built
# result is bit-for-bit identical -- no matter how much Nix source moved around.
#
# Two layers are recorded:
#   drv.txt        target -> .drv path.   Exact, all-or-nothing verdict.
#   names/<t>.txt  sorted derivation names in the closure. Human-readable, and
#                  survives nixpkgs bumps well enough to still be diffable.
#
# Everything is *evaluated*, never built, so all hosts can be checked from any
# machine (a Darwin laptop can snapshot the x86_64-linux hosts).
#
# @see: https://github.com/Gabriella439/nix-diff for drilling into a mismatch

set -e

# shellcheck disable=SC1007 # `CDPATH= cd` is the intended idiom
REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
SNAP_DIR="$REPO_ROOT/tests/snapshots"

usage() {
  cat <<'EOF'
usage: snapshot.sh <command>

  record   Evaluate every host and write snapshots to tests/snapshots/
  check    Re-evaluate and diff against the recorded snapshots
  targets  List the flake targets that will be snapshotted
  explain  Run nix-diff on a target that `check` reported as changed

Typical refactor loop:
  just snap          # before: record the baseline
  ...refactor...
  just snap-check    # after: prove nothing changed
EOF
}

# Enumerate the flake's configuration outputs so a newly added host is picked up
# automatically. A snapshot suite that silently misses a host is worse than none.
#
# Emits lines of: <label><TAB><flake attr path to a derivation>
targets() {
  _enumerate nixosConfigurations 'config.system.build.toplevel'
  _enumerate darwinConfigurations 'config.system.build.toplevel'
  _enumerate homeConfigurations 'activationPackage'
}

_enumerate() {
  output="$1"
  suffix="$2"

  names=$(nix eval --json ".#$output" --apply builtins.attrNames 2>/dev/null) || return 0

  echo "$names" | tr ',' '\n' | sed 's/[][]//g; s/^"//; s/"$//' | while read -r name; do
    [ -n "$name" ] || continue
    printf '%s\t.#%s."%s".%s\n' "$output/$name" "$output" "$name" "$suffix"
  done
}

# Filename-safe label
_slug() {
  echo "$1" | tr '/@' '__'
}

_generate() {
  dest="$1"
  mkdir -p "$dest/names"
  : > "$dest/drv.txt"

  targets | while IFS="$(printf '\t')" read -r label attr; do
    printf '  evaluating %s ... ' "$label" >&2

    drv=$(nix eval --raw "$attr.drvPath" 2>/dev/null)
    printf '%s\t%s\n' "$label" "$drv" >> "$dest/drv.txt"

    # Closure by derivation *name*, hashes stripped. This is the layer a human
    # can actually read when the exact hash comparison says "something moved".
    nix derivation show --recursive "$attr" 2>/dev/null \
      | jq --raw-output '.derivations | keys[]' \
      | sed 's|.*/||; s|^[a-z0-9]\{32\}-||; s|\.drv$||' \
      | sort --unique > "$dest/names/$(_slug "$label").txt"

    printf 'ok\n' >&2
  done
}

cmd_record() {
  echo "--- Recording snapshots ---" >&2
  _generate "$SNAP_DIR"
  echo "--- Wrote $SNAP_DIR ---" >&2
  wc -l "$SNAP_DIR/drv.txt" "$SNAP_DIR"/names/*.txt | sed 's|'"$REPO_ROOT"'/||'
}

cmd_check() {
  if [ ! -f "$SNAP_DIR/drv.txt" ]; then
    echo "No snapshot recorded yet. Run: just snap" >&2
    exit 1
  fi

  tmp=$(mktemp -d)
  # shellcheck disable=SC2064
  trap "rm -rf '$tmp'" EXIT

  echo "--- Checking against recorded snapshots ---" >&2
  _generate "$tmp"

  if diff --unified "$SNAP_DIR/drv.txt" "$tmp/drv.txt" > "$tmp/drv.diff" 2>&1; then
    echo
    echo "PASS: all $(wc -l < "$SNAP_DIR/drv.txt" | tr -d ' ') targets are byte-identical."
    echo "      The refactor changed no build output."
    return 0
  fi

  echo
  echo "CHANGED: derivation hashes differ."
  echo

  # Which targets moved?
  changed=$(diff "$SNAP_DIR/drv.txt" "$tmp/drv.txt" \
    | grep '^[<>]' | awk '{print $2}' | sort --unique)

  for label in $changed; do
    slug=$(_slug "$label")
    old="$SNAP_DIR/names/$slug.txt"
    new="$tmp/names/$slug.txt"

    echo "=== $label"
    if [ -f "$old" ] && [ -f "$new" ]; then
      if diff --unified=0 "$old" "$new" | grep --extended-regexp '^[-+][^-+]' > "$tmp/names.diff"; then
        echo "    closure contents changed:"
        sed 's/^/      /' "$tmp/names.diff"
      else
        echo "    closure package list is IDENTICAL -- only hashes moved."
        echo "    (a build input changed content without changing any package name)"
      fi
    else
      echo "    new or removed target"
    fi
    echo
  done

  echo "Drill down to the exact cause with:"
  echo "  sh scripts/snapshot.sh explain <target>"
  echo
  echo "Accept these changes with:"
  echo "  just snap"
  return 1
}

cmd_explain() {
  label="$1"
  [ -n "$label" ] || { echo "usage: snapshot.sh explain <target>" >&2; exit 1; }

  old=$(grep "^$label	" "$SNAP_DIR/drv.txt" | cut -f2) \
    || { echo "no recorded snapshot for '$label'" >&2; exit 1; }
  attr=$(targets | grep "^$label	" | cut -f2)
  new=$(nix eval --raw "$attr.drvPath" 2>/dev/null)

  if [ "$old" = "$new" ]; then
    echo "$label is unchanged."
    return 0
  fi

  # nix-diff dumps whole buildEnv JSON blobs by default, which is unreadable for
  # a NixOS/home-manager closure. Fold already-compared subtrees, keep context
  # tight, and hard-wrap the pathological lines.
  echo "--- nix-diff: recorded vs current ---"
  nix run nixpkgs#nix-diff -- \
    --line-oriented \
    --context 2 \
    --skip-already-compared \
    "$old" "$new" 2>/dev/null \
    | cut -c1-200
}

case "${1:-}" in
  record) cmd_record ;;
  check) cmd_check ;;
  targets) targets | cut -f1 ;;
  explain) shift; cmd_explain "$@" ;;
  *) usage; exit 1 ;;
esac
