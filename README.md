# Various nix configurations

This repo is my nix/nixos configurations for a few systems. It's quite disorganised, take snippets but don't copy the whole thing, it has some bad ideas I haven't fixed yet.

## Installing

### macOS

If you have Netskope (corpo MitM software) set that up [https://jackrose.co.nz/til/reliable-nix-netskope-install/](https://jackrose.co.nz/til/reliable-nix-netskope-install/)

```bash
# install nix with nice defaults
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# install and setup this config
sudo mv /etc/nix/nix.conf /etc/nix/nix.conf.before-nix-darwin
nix run nix-darwin --extra-experimental-features nix-command --extra-experimental-features flakes -- switch --flake .#(hostname)
```

### NixOS

```bash
# install as per manual then enable flakes
nix shell nixpkgs#just --command just switch # install and setup everything
```

## Hosts

Hosts are named after a New Zealand birds

### Tui

Personal laptop, x86

### Kakapo

Home media server, x86

### jjack-XMW16X

Work laptop M1, just using home-manager as a brew replacement and config manager. Not using nix-darwin as I suspect it would have bad interactions with the MDM and other security software.

### Moa

A VM on my work laptop, work in progress, not currently used.

### Pukeko

A small ARM box on AWS, only has 500MB ram so I build locally with a `just` script.
