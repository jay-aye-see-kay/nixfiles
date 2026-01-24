alias s := switch
alias b := build

default:
  just --list

update:
  nix flake update

update-neovim:
  nix flake update neovim-flake

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

stow:
  stow -d ./dots -t ~ .

unstow:
  stow -d ./dots -t ~ -D .

switch: update-neovim
  #!/bin/sh
  if [ "$(uname)" = "Darwin" ]; then
    home-manager switch --flake ".#$(whoami)@$(hostname)"
  else
    nixos-rebuild --use-remote-sudo switch --flake .#
  fi
  just stow

build: update-neovim
  #!/bin/sh
  if [ "$(uname)" = "Darwin" ]; then
    home-manager build --flake ".#$(whoami)@$(hostname)"
  else
    nixos-rebuild --use-remote-sudo build --flake .#
  fi
