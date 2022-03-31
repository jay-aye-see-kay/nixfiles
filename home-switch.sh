#!/bin/sh

nix build .#homeManagerConfigurations.jack.activationPackage \
  && ./result/activate
