#!/bin/sh

if [ $(uname) == "Darwin" ]; then
  config_name="jack-mbp"
else
  config_name="jack"
fi

nix build ".#homeManagerConfigurations.${config_name}.activationPackage" \
  && ./result/activate
