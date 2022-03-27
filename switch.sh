#!/bin/sh

sudo nixos-rebuild switch --flake .# \
  && ./home-switch.sh
