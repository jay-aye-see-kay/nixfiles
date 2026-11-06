{ lib, pkgs, ... }:
let
  publicKeys = import ../../publicKeys.nix;
  authorizedKeys = with publicKeys; [
    tuiJack
    keaJack
    iSH
  ];
in
{
  imports = [
    ./hardware.nix
    ./disko.nix
    ./tailscale-services.nix
    ./readeck.nix
  ];

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;

    supportedFilesystems = [ "zfs" ];
    zfs.requestEncryptionCredentials = true;
    # Fresh pool with a fixed hostId, so never force-import (the 26.11 default)
    zfs.forceImportRoot = false;

    # Remote unlock: SSH in the initrd on port 2222, LAN only (or via the
    # UniFi WireGuard VPN from away). Logging in drops straight into the
    # passphrase prompt. See home-server/REMOTE-UNLOCK.md in dumpbox.
    # @see: https://elis.nu/blog/2026/04/nixos-zfs-remote-unlock-over-ssh/
    initrd = {
      systemd.enable = true;
      # Onboard Realtek RTL8111 (enp34s0)
      availableKernelModules = [ "r8169" ];
      systemd.network = {
        enable = true;
        networks."10-lan" = {
          matchConfig.Name = "enp34s0";
          networkConfig.DHCP = "yes";
          # The initrd has no persistent machine-id, so the default DUID-based
          # client ID changes every boot and so does the lease. The MAC doesn't.
          dhcpV4Config.ClientIdentifier = "mac";
        };
      };
      network.ssh = {
        enable = true;
        port = 2222;
        # Separate from the main host key, so it's fine that it sits
        # unencrypted in the initrd on the ESP. Created before install and
        # copied in with nixos-anywhere --extra-files.
        hostKeys = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
        inherit authorizedKeys;
      };
      systemd.users.root.shell = "/bin/systemd-tty-ask-password-agent";
    };
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

  # Weekly upgrades from GitHub, but kernel reboots are done by hand (roughly
  # monthly) because each one needs the root passphrase over SSH.
  system.autoUpgrade.allowReboot = lib.mkForce false;

  # NEVER CHANGE THIS
  system.stateVersion = "26.05"; # Did you read the comment?
}
