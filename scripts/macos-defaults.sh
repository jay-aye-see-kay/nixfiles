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

# --- Input: trackpad & mouse -------------------------------------------------
# Tracking speed (gestures/tap settings are all left at factory default).
defaults write -g com.apple.trackpad.scaling -float 2.5
defaults write -g com.apple.mouse.scaling -float 2.5

# --- Finder ------------------------------------------------------------------
defaults write -g AppleShowAllExtensions -bool true              # show all file extensions
defaults write com.apple.finder FXPreferredViewStyle -string Nlsv          # default to list view
defaults write com.apple.finder ShowPathbar -bool true                     # show path bar
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false # no warning on ext change
defaults write com.apple.finder ShowRecentTags -bool false                 # hide recent tags in sidebar
defaults write com.apple.finder FXDefaultSearchScope -string SCev          # search "This Mac" by default

# --- Dock --------------------------------------------------------------------
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock tilesize -int 44

# --- Menu bar clock ----------------------------------------------------------
defaults write com.apple.menuextra.clock ShowDate -int 0         # hide date in menu bar clock

# --- Apply -------------------------------------------------------------------
killall Finder Dock SystemUIServer 2>/dev/null || true
