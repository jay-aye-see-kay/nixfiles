alias s := switch
alias hs := home-switch

default:
  just --list

update:
  nix flake update

update-neovim:
  nix flake lock --update-input neovim-flake

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
  nix flake lock --update-input $CHOSEN

home-switch:
  home-manager switch --flake ".#$(whoami)@$(hostname)"

pukeko-switch:
  nixos-rebuild switch \
    --flake '.#pukeko' \
    --target-host root@pukeko

switch:
  #!/bin/sh
  if [ "$(uname)" = "Darwin" ]; then
    darwin-rebuild switch --flake .#$(hostname)
  else
    nixos-rebuild --use-remote-sudo switch --flake .#
  fi
