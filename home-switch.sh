#!/bin/sh

if [ "$(uname -m)" = "arm64" ]; then
  arch="aarch64"
else
  arch="$(uname -m)"
fi

kernel="$(uname | tr "[:upper:]" "[:lower:]")"
system="${arch}-${kernel}"

nix build ".#homeManagerConfigurations.$(whoami).${system}.activationPackage" &&
	./result/activate
