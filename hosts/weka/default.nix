# weka, the home server. See README.md for what spans several modules and
# the state that lives outside the repo.
{ pkgs, ... }:
let
  publicKeys = import ../../publicKeys.nix;
  authorizedKeys = with publicKeys; [
    tuiJack
    keaJack
    iSH
    laTerminal
  ];
in
{
  imports = [
    # Disks, pools, power, unlocking at boot
    ./base
    # Tailscale Services and Homepage, which every app plugs into
    ./platform
    ./backup
    ./monitoring
    ./apps
  ];

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;

    supportedFilesystems = [ "zfs" ];
    # Fresh pool with a fixed hostId, so never force-import (the 26.11 default)
    zfs.forceImportRoot = false;
  };

  networking = {
    hostName = "weka";
    # for zfs, random
    hostId = "f0181f64";
  };

  time.timeZone = "Australia/Melbourne";
  i18n.defaultLocale = "en_AU.UTF-8";

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  # Joined once by hand as a tagged device (tag:server: no key expiry, needed
  # for Tailscale Services). The node key lives in /var/lib/tailscale on the
  # encrypted root, so no auth key is kept around. Make a new one to reinstall.
  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  # Secrets in ./secrets.yaml (edit with `just weka-secrets`), decrypted at
  # activation into /run/secrets with the age key derived from the SSH host key.
  # @see: https://github.com/Mic92/sops-nix
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    # age only, don't also import the RSA host key as a GPG key
    gnupg.sshKeyPaths = [ ];
  };

  services.zfs = {
    trim.enable = true;
    autoScrub.enable = true;
  };

  users.users.root.openssh.authorizedKeys.keys = authorizedKeys;

  users.users.jack = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = authorizedKeys;
  };

  programs.fish.enable = true;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  # Allow passwordless sudo for wheel group (for remote deploys)
  security.sudo.wheelNeedsPassword = false;

  # NEVER CHANGE THIS
  system.stateVersion = "26.05"; # Did you read the comment?
}
