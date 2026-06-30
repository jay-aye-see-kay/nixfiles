#!/bin/sh
set -e

# Applies per-user macOS settings via `defaults write` and friends.
#
# Runs automatically at the end of `just switch` on Darwin hosts. Covers things
# that home-manager / nix can't manage on this setup (no nix-darwin): Finder
# display options, trackpad behaviour, menu bar / Control Center, etc.
#
# IMPORTANT: everything in here must be NO SUDO required. Only write to per-user
# domains (~/Library/Preferences). Anything needing admin/sudo (hostname,
# firewall, /Library/Preferences, FileVault, pmset, Touch ID for sudo) does NOT
# belong here - it would break the unattended `just switch` flow by prompting
# for a password. Keep this script idempotent so repeated runs are safe.
#
# Only non-default settings are captured here. To see what a domain currently
# holds: `defaults read <domain>` (or `defaults read -g` for NSGlobalDomain).
#
# NOT captured (and why):
#   - Login items: no legacy login items exist; apps launch via SMAppService,
#     which `defaults` can't manage. Use home-manager launchd.agents if needed.
#   - Menu bar / Control Center visible items: stored as opaque binary blobs
#     (MenuBarCustomizationState), not cleanly scriptable.

# Apps that need restarting because a value actually changed.
RESTART=""

# dwrite <domain> <key> <type> <value>
# Writes the default only if the current value differs, and queues the matching
# app(s) for restart. Maps domains to the process that must be killed to pick
# up the change.
dwrite() {
  domain=$1
  key=$2
  type=$3
  value=$4

  # Normalise the expected value to how `defaults read` reports it, so the
  # comparison is apples-to-apples (bools come back as 1/0).
  expected=$value
  if [ "$type" = "-bool" ]; then
    case "$value" in
      true|yes|1)  expected=1 ;;
      false|no|0)  expected=0 ;;
    esac
  fi

  old=$(defaults read "$domain" "$key" 2>/dev/null || echo "__UNSET__")
  if [ "$old" = "$expected" ]; then
    return
  fi

  defaults write "$domain" "$key" "$type" "$value"

  case "$domain" in
    com.apple.finder)       apps="Finder" ;;
    com.apple.dock)         apps="Dock" ;;
    com.apple.menuextra.*)  apps="SystemUIServer" ;;
    -g|NSGlobalDomain)      apps="Finder Dock SystemUIServer" ;;
    *)                      apps="" ;;
  esac
  RESTART="$RESTART $apps"
}

# --- Input: trackpad & mouse -------------------------------------------------
# Tracking speed (gestures/tap settings are all left at factory default).
dwrite -g com.apple.trackpad.scaling -float 2.5
dwrite -g com.apple.mouse.scaling -float 2.5

# --- Finder ------------------------------------------------------------------
dwrite -g AppleShowAllExtensions -bool true              # show all file extensions
dwrite com.apple.finder FXPreferredViewStyle -string Nlsv          # default to list view
dwrite com.apple.finder ShowPathbar -bool true                     # show path bar
dwrite com.apple.finder FXEnableExtensionChangeWarning -bool false # no warning on ext change
dwrite com.apple.finder ShowRecentTags -bool false                 # hide recent tags in sidebar
dwrite com.apple.finder FXDefaultSearchScope -string SCev          # search "This Mac" by default

# --- Dock --------------------------------------------------------------------
dwrite com.apple.dock autohide -bool true
dwrite com.apple.dock tilesize -int 44

# --- Menu bar clock ----------------------------------------------------------
dwrite com.apple.menuextra.clock ShowDate -int 0         # hide date in menu bar clock

# --- Apply -------------------------------------------------------------------
# Only restart apps whose values actually changed - avoids the flicker on no-op runs.
if [ -n "$RESTART" ]; then
  # Dedupe the accumulated app list.
  apps=$(printf '%s\n' $RESTART | sort -u | tr '\n' ' ')
  echo "Restarting:$apps"
  # shellcheck disable=SC2086
  killall $apps 2>/dev/null || true
fi
