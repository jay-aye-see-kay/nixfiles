{ config, pkgs, ... }:
let publicKeys = import ../../publicKeys.nix;
in
{
  imports = [
    ./hardware.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # allow this machine to build for arm using qemu
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

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

  services.gnome.gnome-keyring.enable = true;
  programs._1password.enable = true;
  programs._1password-gui.enable = true;

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  programs.nm-applet.enable = true;
  programs.fish.enable = true;

  users.users.jack = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [ "wheel" "docker" "networkmanager" "video" ];
    openssh.authorizedKeys.keys = [ publicKeys.deskJack ];
  };

  virtualisation.docker.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    age
    alacritty
    chromium
    dbeaver
    docker-compose
    freecad
    inkscape
    libnotify
    libreoffice
    lm_sensors
    neovim
    slack
    wireshark
    wireshark-cli
    mullvad-vpn
    pulsemixer
    qbittorrent
    flyctl
    zathura
  ];

  # This option enables Mullvad VPN daemon. This sets networking.firewall.checkReversePath
  # to "loose", which might be undesirable for security.
  services.mullvad-vpn.enable = true;

  # auto mount usb drives
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.devmon.enable = true;

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
