{ config, lib, pkgs, ... }:
let
  # clevis, but leaving /run/clevis-unlocked behind when a decrypt succeeds.
  # The import prints nothing either way, and /run carries over from the
  # initrd, so stage 2 can tell an unattended unlock from a passphrase one
  # (boot_unlocked_by_clevis in monitoring.nix).
  clevisMarked = pkgs.writeShellScript "clevis" ''
    if [ "$1" = decrypt ]; then
      ${config.boot.initrd.clevis.package}/bin/clevis "$@" && : > /run/clevis-unlocked
    else
      exec ${config.boot.initrd.clevis.package}/bin/clevis "$@"
    fi
  '';
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
    ./hardware.nix
    ./disko.nix
    ./tailscale-services.nix
    ./sanoid.nix
    ./restic.nix
    ./monitoring.nix
    ./grafana.nix
    ./logs.nix
    ./readeck.nix
    ./mealie.nix
    ./files.nix
    ./paperless.nix
    ./homepage.nix
    ./vacuum.nix
    ./home-assistant.nix
    ./tank1.nix
    ./ups.nix
    ./jellyfin.nix
    ./plex.nix
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
    # passphrase prompt. See "Reboots and unlocking" in README.md.
    # @see: https://elis.nu/blog/2026/04/nixos-zfs-remote-unlock-over-ssh/
    initrd = {
      systemd.enable = true;
      # Onboard Realtek RTL8111, renamed to lan0 (see systemd.network.links)
      availableKernelModules = [ "r8169" ];
      systemd.network = {
        enable = true;
        networks."10-lan" = {
          matchConfig.Name = "lan0";
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
        # unencrypted in the initrd on the ESP. Kept in 1Password and copied
        # in with nixos-anywhere --extra-files at install (see README.md).
        hostKeys = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
        inherit authorizedKeys;
      };
      systemd.users.root.shell = "/bin/systemd-tty-ask-password-agent";

      # Auto-unlock: clevis gets the passphrase back from a Tang server (keystone,
      # a Cloudflare Worker deployed from the infra repo, gated to the home IP).
      # If that fails, the import falls through to the passphrase prompt above.
      # The .jwe holds the passphrase sealed to the Tang key, so like the SSH
      # host key it stays out of the store and this repo (string path, copied
      # in by boot.initrd.secrets). Made by hand, see "Reboots and unlocking".
      # @see: https://github.com/jay-aye-see-kay/nixfiles/issues/4
      clevis = {
        enable = true;
        useTang = true;
        devices."rpool/crypt".secretFile = "/etc/secrets/initrd/rpool-crypt.jwe";
      };
      # The clevis module adds curl but no CA bundle, so HTTPS would fail
      systemd.contents."/etc/ssl/certs/ca-certificates.crt".source = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      # clevis-decrypt-tang makes one curl call and the import runs it once,
      # so retry here. Long enough for the router and internet to come back
      # after a power cut, short enough that the passphrase fallback (which
      # waits for this) isn't a chore. Worst case 10 attempts x 6s + 9 x 3s =
      # 87s (max-time also cuts clevis's own 10s connect timeout).
      # IPv4 only, since the Tang key set allows only the home IPv4.
      systemd.contents."/etc/curl/.curlrc".text = ''
        retry = 9
        retry-delay = 3
        retry-all-errors
        max-time = 6
        retry-max-time = 90
        ipv4
        cacert = /etc/ssl/certs/ca-certificates.crt
      '';
      systemd.services.zfs-import-rpool.environment.CURL_HOME = "/etc/curl";
      systemd.extraBin.clevis = lib.mkForce clevisMarked;
      systemd.storePaths = [ clevisMarked ];
    };
  };

  networking = {
    hostName = "weka";
    # for zfs, random
    hostId = "f0181f64";
  };

  # A fixed name for the onboard NIC. The kernel's name comes from the PCI
  # path, so it would change with the board. Everything else refers to lan0.
  # Matched on the driver rather than Type=ether, which would also catch
  # podman's veths.
  # nixpkgs copies .link files into the initrd too, so the unlock network
  # gets the same name.
  systemd.network.links."10-lan0" = {
    matchConfig.Driver = "r8169";
    linkConfig.Name = "lan0";
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

  # Weekly upgrades from GitHub reboot by themselves when the kernel or initrd
  # changed (03:00-05:00, see modules/nixos/common.nix): the root pool unlocks
  # from Tang, see boot.initrd.clevis above.

  # TEMPORARY (#4): reboot daily for a few weeks, to prove auto-unlock holds
  # up. 04:30 is after restic (02:00), syncoid (03:30) and the Sunday upgrade
  # (03:00 + up to 30 min); it skips the night if any of them is still going.
  # boot_unlocked_by_clevis (monitoring.nix) records how each boot unlocked.
  systemd.services.unlock-test-reboot = {
    description = "Daily reboot to test auto-unlock (temporary)";
    serviceConfig.Type = "oneshot";
    script = ''
      for unit in nixos-upgrade restic-backups-weka syncoid-rpool-crypt-data; do
        if systemctl is-active --quiet "$unit.service"; then
          echo "$unit is still running, not rebooting tonight"
          exit 0
        fi
      done
      systemctl reboot
    '';
    startAt = "*-*-* 04:30:00";
  };

  # NEVER CHANGE THIS
  system.stateVersion = "26.05"; # Did you read the comment?
}
