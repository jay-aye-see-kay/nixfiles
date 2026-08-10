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

innie-deploy:
  nix run nixpkgs#nixos-rebuild -- switch --flake .#innie --build-host jack@innie --target-host jack@innie --sudo

honey-deploy:
  nix run nixpkgs#nixos-rebuild -- switch --flake .#honey --build-host jack@honey --target-host jack@honey --sudo
