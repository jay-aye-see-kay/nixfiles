#!/bin/sh

kernel="$(uname | tr "[:upper:]" "[:lower:]")"
system="$(uname -m)-${kernel}"

nix build ".#homeManagerConfigurations.$(whoami).${system}.activationPackage" &&
	./result/activate
