#!/bin/sh

if [ "$(uname)" = "Darwin" ]; then
	config_name="jack-mbp"
elif [ "$(uname -m)" = "aarch64" ]; then
	config_name="jack-aarch64"
else
	config_name="jack"
fi

nix build ".#homeManagerConfigurations.${config_name}.activationPackage" &&
	./result/activate
