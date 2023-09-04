{ config, pkgs, ... }:
let
  publicKeys = import ../../publicKeys.nix;
in
{
  imports = [
    ./hardware.nix
  ];

  powerManagement = {
    powertop.enable = true;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # allow this machine to build for arm using qemu
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # ZFS boot settings.
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.devNodes = "/dev/";
  boot.zfs.requestEncryptionCredentials = true;

  networking.hostName = "kakapo";
  networking.hostId = "e319c2ad"; # for zfs; 'hostname | md5sum | head -c 8'

  boot = {
    # see: https://nixos.wiki/wiki/ZFS#Unlock_encrypted_zfs_via_ssh_on_boot
    initrd.network = {
      enable = true;
      ssh = {
        enable = true;
        port = 2222;
        hostKeys = [ /root/.ssh/boot_ed25519_key ];
        authorizedKeys = [
          publicKeys.tuiJack
          publicKeys.deskJack
        ];
      };
      postCommands = ''
        zpool import rpool
        zpool import apool
        echo "zfs load-key -a; killall zfs" >> /root/.profile
      '';
    };
  };

  time.timeZone = "Australia/Melbourne";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp7s0.useDHCP = true;

  programs.fish.enable = true;

  users.users.jack = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [ "wheel" "docker" "podman" ];
    openssh.authorizedKeys.keys = [
      publicKeys.tuiJack
      publicKeys.deskJack
    ];
  };

  # OCI container setup for Arion (should work for most docker [compose] stuff too)
  virtualisation = {
    docker.enable = true;
    docker.package = pkgs.unstable.docker;
    oci-containers.backend = "docker";
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    age
    neovim
    arion # for running web services
    unstable.docker
    unstable.docker-compose
    smartmontools
    mullvad-vpn
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # https://nixos.wiki/wiki/Binary_Cache
  services.nix-serve = {
    enable = true;
    secretKeyFile = "/var/cache-priv-key.pem";
  };

  networking.firewall = {
    allowedUDPPorts = [
      53 # dns
      80 # http
      443 # https
      465 # smtp
      25565 # minecraft
      51820 # wireguard
      8080 # kodi
      8443 # matrix-synapse
      32410 # plex network discovery
      32412 # plex network discovery
      32413 # plex network discovery
      32414 # plex network discovery
    ];
    allowedTCPPorts = [
      53 # dns
      80 # http
      443 # https
      465 # smtp
      25565 # minecraft
      8080 # kodi
      8443 # matrix-synapse
      32400 # plex
    ];
  };

  # ignore power key (it's a server, it should be hard to shutdown/sleep)
  services.logind.extraConfig = ''
    HandlePowerKey=ignore
    HandlePowerKeyLongPress=ignore
    HandleRebootKey=ignore
    HandleRebootKeyLongPress=ignore
    HandleSuspendKey=ignore
    HandleSuspendKeyLongPress=ignore
    HandleHibernateKey=ignore
    HandleHibernateKeyLongPress=ignore
    HandleLidSwitch=ignore
    HandleLidSwitchExternalPower=ignore
    HandleLidSwitchDocked=ignore
  '';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
