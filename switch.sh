#!/bin/sh

if [ $(uname) == "Darwin" ]; then
  echo "macos not supported, did you mean ./home-switch.sh instead?"
  exit 1
fi

nixos-rebuild  --use-remote-sudo switch --flake .# \
  && ./home-switch.sh
