{ config, pkgs, ... }:
let
  publicKeys = import ../../publicKeys.nix;
in
{
  imports = [ ./hardware.nix ./sway.nix ];

  nix = {
    package = pkgs.nixFlakes; # or versioned attributes like nix_2_7
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    settings.auto-optimise-store = true;
  };

  powerManagement = {
    cpuFreqGovernor = "ondemand";
    powertop.enable = true;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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
    oci-containers.backend = "docker";
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    age
    fd
    git
    neovim
    nmap
    pciutils # provides lspci
    pwgen
    ripgrep
    sops
    tldr
    btop
    stress
    parted
    progress
    powertop
    hdparm
    arion # for running web services
    docker
    docker-compose
    smartmontools
    mullvad-vpn
  ];

  # hud setup for the tv
  users.users.hud = {
    isNormalUser = true;
    extraGroups = [ ];
  };
  services.xserver.enable = true;
  services.xserver.displayManager = {
    lightdm.enable = true;
    autoLogin.enable = true;
    autoLogin.user = "hud";
  };

  services.mullvad-vpn.enable = true;

  services.borgbackup.jobs.home-server-volumes = {
    paths = "/hs";
    repo = "q276grru@q276grru.repo.borgbase.com:repo";
    startAt = "*-*-* 04:00:00"; # daily @ 4am
    compression = "auto,zstd";
    encryption = {
      mode = "repokey-blake2";
      passCommand = "cat ${config.sops.secrets.borgPassword.path}";
    };
    # stop all containers so we don't get corrupt databases
    preHook = ''
      cd /home/jack/home-server-dc
      ${pkgs.docker-compose}/bin/docker-compose stop
    '';
    # update images and start containers
    postHook = ''
      cd /home/jack/home-server-dc
      ${pkgs.docker-compose}/bin/docker-compose pull
      ${pkgs.docker-compose}/bin/docker-compose up -d --remove-orphans
      ${pkgs.docker}/bin/docker stop $(${pkgs.docker}/bin/docker ps --filter="label=startstopped" --quiet)
    '';
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  networking.firewall = {
    allowedUDPPorts = [
      53 # dns
      465 # smtp
      25565 # minecraft
      51820 # wireguard
      8080 # kodi
      8443 # matrix-synapse
    ];
    allowedTCPPorts = [
      53 # dns
      80 # http
      443 # https
      465 # smtp
      25565 # minecraft
      8080 # kodi
      8443 # matrix-synapse
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
