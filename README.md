# Various nix configurations

This repo is my nix/nixos configurations for a few systems. It's quite disorganised, take snippets but don't copy the whole thing, it has some bad ideas I haven't fixed yet.

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

## Secrets

Currently using `sops` for secrets management, it does seem a little over complicated for my use cases (I'm not sure if I am actively using it right now). I do like the idea of having secrets mixed in with my config and synced between machines, but I'm not finding the current setup great.

Some misc commands that are useful:

```bash
# update the encrypted file after changing config
nix-shell -p sops --run "sops updatekeys secrets/main.yaml"

# generate private age key from ssh key
mkdir -p ~/.config/sops/age
nix-shell -p ssh-to-age --run "ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt"

# show public key from private key (add this to `.sops.yaml`)
nix-shell -p age --run "age-keygen -y ~/.config/sops/age/keys.txt"
```
