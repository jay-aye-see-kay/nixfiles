# Various nix configurations

This repo is my nix/nixos configurations for a few systems. It's quite disorganised, take snippets but don't copy the whole thing, it has some bad ideas I haven't fixed yet.

## Installing

### macOS

If you have Netskope (corpo MitM software) set that up [https://jackrose.co.nz/til/reliable-nix-netskope-install/](https://jackrose.co.nz/til/reliable-nix-netskope-install/)

```bash
# install nix with nice defaults (enables flakes, allows user to set substituters)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --extra-conf "trusted-users = root $(whoami)"
nix shell nixpkgs#home-manager nixpkgs#just --command just switch # install and setup everything
```

### NixOS

```bash
# install as per manual then enable flakes
nix shell nixpkgs#just --command just switch # install and setup everything
```

## Hosts

Most hosts are named after a New Zealand bird. Work machines keep the name given by the corporate MDM.

### tui

Personal laptop (Thinkpad X1 6th gen, x86), NixOS with sway, ZFS on root and home-manager as a NixOS module.

### kea

Personal laptop (M-series mac), home-manager only.

### jrose-04LCLG

Work laptop (M-series mac), just using home-manager as a brew replacement and config manager. Not using nix-darwin as I suspect it would have bad interactions with the MDM and other security software.

### honey

VM on the home server, runs the media and web services: caddy, jellyfin, plex, mealie, linkding and readeck. Deploy with `just honey-deploy`.

### innie

VM on the home server, runs file and document services: samba, paperless and vsftpd. Deploy with `just innie-deploy`.
