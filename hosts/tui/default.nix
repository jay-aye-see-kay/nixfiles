{ config, pkgs, ... }:
let publicKeys = import ../../publicKeys.nix;
in
{
  imports = [ ./hardware.nix ];

  nix = {
    package = pkgs.nixFlakes; # or versioned attributes like nix_2_7
    # second two for nix-direnv
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';
  };
  nixpkgs.config.allowUnfree = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ZFS boot settings.
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.devNodes = "/dev/";
  boot.zfs.requestEncryptionCredentials = true;

  # ZFS maintenance settings.
  services.zfs.trim.enable = true;
  services.zfs.autoScrub.enable = true;
  services.zfs.autoScrub.pools = [ "rpool" ];

  networking.hostName = "tui"; # Define your hostname.
  networking.hostId = "90cabfac"; # for zfs; 'hostname | md5sum | head -c 8'
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Australia/Melbourne";
  # Select internationalisation properties.
  i18n.defaultLocale = "en_AU.UTF-8";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp0s31f6.useDHCP = true;
  networking.interfaces.wlp2s0.useDHCP = true;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  programs.nm-applet.enable = true;

  users.users.jack = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [ "wheel" "docker" "networkmanager" "video" ];
    openssh.authorizedKeys.keys = [ publicKeys.deskJack ];
  };

  virtualisation.docker.enable = true;
  services.k3s.enable = true;
  services.k3s.docker = true;
  services.k3s.role = "server";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    _1password
    _1password-gui
    age
    alacritty
    btop
    chromium
    dbeaver
    docker-compose
    fd
    firefox
    freecad
    git
    hdparm
    inkscape
    libnotify
    libreoffice
    lm_sensors
    neovim
    nmap
    parted
    pciutils # provides lspci
    slack
    powertop
    progress
    pwgen
    ripgrep
    sops
    stress
    tldr
    wget
    wireshark
    wireshark-cli
    mullvad-vpn
    pulsemixer
    qbittorrent
  ];

  # This option enables Mullvad VPN daemon. This sets networking.firewall.checkReversePath
  # to "loose", which might be undesirable for security.
  services.mullvad-vpn.enable = true;

  # disable firewall so chromecast can work
  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
}
