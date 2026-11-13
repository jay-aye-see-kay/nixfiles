alias s := switch
alias b := build

default:
  just --list

update:
  nix flake update

update-one:
  #!/bin/sh
  CHOSEN=$(nix flake metadata --json \
    | jq  '.locks.nodes | keys | join(" ")' \
    | sed 's/"//g' \
    | sed 's/ /\n/g' \
    | fzf)
  echo "---"
  echo "Updating ${CHOSEN}..."
  echo "---"
  nix flake update $CHOSEN

switch:
  #!/bin/sh
  if [ "$(uname)" = "Darwin" ]; then
    home-manager switch --flake ".#$(whoami)@$(hostname)"
    just macos-defaults
  else
    nixos-rebuild --sudo switch --flake .#
  fi
  just nvim-sync

# Apply per-user macOS settings (Finder, trackpad, menu bar, etc) - Darwin only, no sudo
macos-defaults:
  #!/bin/sh
  if [ "$(uname)" = "Darwin" ]; then
    echo "--- Applying macOS defaults ---"
    sh {{justfile_directory()}}/scripts/macos-defaults.sh
  fi

# Show Rex app settings changed in its UI that differ from modules/home-manager/rex.nix
rex-diff:
  sh {{justfile_directory()}}/scripts/rex-settings.sh diff

# Copy Rex's live custom themes into dots/rex/custom-themes.json
rex-export-themes:
  sh {{justfile_directory()}}/scripts/rex-settings.sh export-themes

# Sync lazy.nvim plugins to match lazy-lock.json (restore) and remove unused (clean)
nvim-sync:
  #!/bin/sh
  if command -v nvim >/dev/null 2>&1; then
    echo "--- Syncing nvim plugins (Lazy restore + clean) ---"
    log=$(mktemp)
    if nvim --headless "+Lazy! restore" "+Lazy! clean" +qa >"$log" 2>&1; then
      echo "nvim plugins synced"
    else
      echo "nvim sync failed:"
      cat "$log"
    fi
    rm -f "$log"
  fi

build:
  #!/bin/sh
  if [ "$(uname)" = "Darwin" ]; then
    home-manager build --flake ".#$(whoami)@$(hostname)"
  else
    nixos-rebuild --sudo build --flake .#
  fi

# Record a snapshot of every host's derivation hash (run BEFORE refactoring)
snap:
  sh {{justfile_directory()}}/scripts/snapshot.sh record

# Prove a refactor changed no build output (run AFTER refactoring)
snap-check:
  sh {{justfile_directory()}}/scripts/snapshot.sh check

# Explain why a target's derivation changed
snap-explain target:
  sh {{justfile_directory()}}/scripts/snapshot.sh explain {{target}}

weka-deploy:
  nix run nixpkgs#nixos-rebuild -- switch --flake .#weka --build-host jack@weka --target-host jack@weka --sudo

# Unlock weka's encrypted ZFS root over initrd SSH, passphrase from 1Password.
# initrd login shell is systemd-tty-ask-password-agent, which needs a tty/-tt
weka-unlock:
  op read "op://Personal/weka zfs/password" | ssh -tt -p 2222 root@192.168.10.101

# Edit weka's sops secrets. The admin age key comes from 1Password via an env
# var, so it's never written to disk.
weka-secrets:
  SOPS_AGE_KEY="$(op read 'op://Personal/nixfiles age key/password')" nix shell nixpkgs#sops -c sops hosts/weka/secrets.yaml

# Regenerate the logos in assets/logos, plus 512px square PNGs for Slack icons
logos:
  #!/bin/sh
  set -e
  cd {{justfile_directory()}}/assets/logos
  tmp=$(mktemp -d)
  nix shell nixpkgs#python3 nixpkgs#librsvg --command sh -c "
    python3 -I generate.py .
    python3 -I generate.py '$tmp' --square
    mkdir -p slack
    for f in weka weka-alerts rosegrove; do
      rsvg-convert --width 512 --height 512 --output slack/\$f.png '$tmp'/\$f.svg
    done"
  rm -rf "$tmp"
