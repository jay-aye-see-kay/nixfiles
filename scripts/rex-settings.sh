#!/bin/sh
set -e

# Compares Rex's live app settings (changed in its Settings window) against
# what modules/home-manager/rex.nix declares, so UI changes can be copied back
# into the repo. macOS only; it never writes to Rex's preferences.
#
#   diff           (default) show tracked keys that changed, untracked keys,
#                  and whether the custom themes differ
#   export-themes  overwrite dots/rex/custom-themes.json with the live themes
#
# Keys listed in IGNORED below are never reported: per-machine state, plus
# settings deliberately left unsynced. Edit that list rather than the output.

# shellcheck disable=SC1007 # `CDPATH= cd` is the intended idiom
REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
DOMAIN="com.superlogical.rex"
PLIST="$HOME/Library/Preferences/$DOMAIN.plist"
THEMES="$REPO_ROOT/dots/rex/custom-themes.json"
HOST_CONFIG="$(whoami)@$(hostname)"

if [ "$(uname)" != "Darwin" ]; then
  echo "rex-settings: macOS only" >&2
  exit 1
fi
if [ ! -f "$PLIST" ]; then
  echo "rex-settings: $PLIST not found (has Rex been run?)" >&2
  exit 1
fi

COMMAND="${1:-diff}"

case "$COMMAND" in
  diff)
    DECLARED=$(cd "$REPO_ROOT" && nix eval --json \
      ".#homeConfigurations.\"$HOST_CONFIG\".config.targets.darwin.defaults.\"$DOMAIN\"" 2>/dev/null)
    python3 -I - "$PLIST" "$THEMES" "$DECLARED" <<'EOF'
import fnmatch, json, plistlib, sys

plist_path, themes_path, declared_json = sys.argv[1:]
live = plistlib.load(open(plist_path, "rb"))
declared = json.loads(declared_json)

IGNORED = [
    # per-machine state, never sync
    "NS*", "SGTRecentFileSearches", "Onboarding.*", "RexSync.*",
    "rex.sync.*", "rex.local-server.*", "SULastCheckTime",
    "SUHasLaunchedBefore", "SUUpdateGroupIdentifier", "SUScheduledCheckInterval",
    "Workspace.lastFocusedSession", "Workspace.programActivitySeen",
    "Workspace.sidebarCollapsed", "rex.server.web-client-origin-patterns",
    # handled separately via dots/rex/custom-themes.json
    "Workspace.customThemes",
    # settings deliberately left per-machine / at Rex's default
    "Workspace.darkThemeID", "Workspace.inactivePaneFadeMode",
    "Workspace.tintsPanesWithProgramBackground",
    "Workspace.usesStandardInactiveWindowPaneStyles",
    "Workspace.terminalFontPointSize", "Workspace.terminalFontSmoothing",
    "Workspace.tabsFillAvailableSpace", "Workspace.tabIconCount",
    "Workspace.tabIconTintMode", "Workspace.sidebarWidth",
    "rex.server.block-plugin-reload-enabled",
]

def ignored(key):
    return any(fnmatch.fnmatchcase(key, p) for p in IGNORED)

def nix(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, float):
        return repr(v) if "." in repr(v) or "e" in repr(v) else repr(v) + ".0"
    if isinstance(v, int):
        return str(v)
    if isinstance(v, str):
        return json.dumps(v)
    if isinstance(v, list) and all(isinstance(x, (str, bool, int, float)) for x in v):
        return "[ " + " ".join(nix(x) for x in v) + " ]"
    return None

def same(a, b):
    # JSON loses the float/int distinction (12.0 -> 12), so compare by value
    return a == b and isinstance(a, bool) == isinstance(b, bool)

changed = [(k, v, live[k]) for k, v in sorted(declared.items()) if k in live and not same(v, live[k])]
missing = [k for k in sorted(declared) if k not in live]
untracked = [k for k in sorted(live) if k not in declared and not ignored(k)]

clean = True
if changed:
    clean = False
    print("Changed in the Rex UI (declared -> live). Update modules/home-manager/rex.nix:")
    for k, old, new in changed:
        print(f"  {json.dumps(k)} = {nix(new) or repr(new)};   # was {nix(old) or repr(old)}")
if untracked:
    clean = False
    print("\nSet in Rex but not in rex.nix. Add to rex.nix, or to IGNORED in scripts/rex-settings.sh:")
    for k in untracked:
        v = live[k]
        print(f"  {json.dumps(k)} = {nix(v) or '<unsupported type ' + type(v).__name__ + '>'};")
if missing:
    print("\nDeclared but absent from the live plist (Rex reset it, or not switched yet):")
    for k in missing:
        print(f"  {k}")

try:
    repo_themes = json.load(open(themes_path))
except FileNotFoundError:
    repo_themes = None
live_themes = json.loads(live["Workspace.customThemes"]) if "Workspace.customThemes" in live else None
if repo_themes != live_themes:
    clean = False
    names = lambda t: sorted(x.get("name", "?") for x in (t or []))
    print("\nCustom themes differ. Run `just rex-export-themes` to copy the live ones into the repo.")
    print(f"  repo: {names(repo_themes)}")
    print(f"  live: {names(live_themes)}")

if clean:
    print("Rex settings match rex.nix.")
EOF
    ;;
  export-themes)
    python3 -I - "$PLIST" "$THEMES" <<'EOF'
import json, plistlib, sys
plist_path, themes_path = sys.argv[1:]
live = plistlib.load(open(plist_path, "rb"))
themes = json.loads(live["Workspace.customThemes"])
with open(themes_path, "w") as f:
    f.write(json.dumps(themes, indent=2) + "\n")
print(f"wrote {len(themes)} theme(s) to {themes_path}")
EOF
    ;;
  *)
    echo "usage: rex-settings.sh [diff|export-themes]" >&2
    exit 1
    ;;
esac
