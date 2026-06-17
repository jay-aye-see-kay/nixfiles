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
  else
    nixos-rebuild --sudo switch --flake .#
  fi

build:
  #!/bin/sh
  if [ "$(uname)" = "Darwin" ]; then
    home-manager build --flake ".#$(whoami)@$(hostname)"
  else
    nixos-rebuild --sudo build --flake .#
  fi

# install a brew/cask and record it in the Brewfile (macOS)
brew-add +args:
  #!/bin/sh
  set -e
  brew install {{args}}
  brew bundle dump --file=modules/home-manager/Brewfile --force

innie-deploy:
  nixos-rebuild switch --flake .#innie --target-host jack@innie --sudo
