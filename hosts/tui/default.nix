{ config, pkgs, ... }:
let publicKeys = import ../../publicKeys.nix;
in
{
  imports = [
    ./hardware.nix
  ];

  boot = {
    # Use the systemd-boot EFI boot loader.
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;

    # allow this machine to build for arm using qemu
    binfmt.emulatedSystems = [ "aarch64-linux" ];

    # ZFS boot settings.
    supportedFilesystems = [ "zfs" ];
    zfs.devNodes = "/dev/";
    zfs.requestEncryptionCredentials = true;
  };

  networking = {
    hostName = "tui"; # Define your hostname.
    hostId = "90cabfac"; # for zfs; 'hostname | md5sum | head -c 8'
    networkmanager.enable = true;
  };

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

  services = {
    # ZFS maintenance settings.
    zfs = {
      trim.enable = true;
      autoScrub.enable = true;
      autoScrub.pools = [ "rpool" ];
    };

    # ZFS auto snapshot
    sanoid = {
      enable = true;
      datasets."rpool/user" = {
        recursive = "zfs";
      };
    };

    # Enable CUPS to print documents.
    printing.enable = true;
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    gnome.gnome-keyring.enable = true;
    blueman.enable = true;

    # This option enables Mullvad VPN daemon. This sets networking.firewall.checkReversePath
    # to "loose", which might be undesirable for security.
    mullvad-vpn.enable = true;

    # auto mount usb drives
    gvfs.enable = true;
    udisks2.enable = true;
    devmon.enable = true;
  };

  programs = {
    _1password.enable = true;
    _1password-gui.enable = true;
    fish.enable = true;
  };

  hardware.bluetooth.enable = true;

  users.users.jack = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [ "wheel" "docker" "networkmanager" "video" ];
    openssh.authorizedKeys.keys = [ publicKeys.deskJack ];
  };

  systemd.services.trash-cli-empty =
    let days-to-keep = "60"; in {
      script = "${pkgs.trash-cli}/bin/trash-empty ${days-to-keep}";
      serviceConfig.User = config.users.users.jack.name;
      startAt = "daily";
    };

  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "zfs";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    age
    alacritty
    chromium
    docker-compose
    freecad
    inkscape
    libnotify
    libreoffice
    lm_sensors
    nnvim
    slack
    wireshark
    wireshark-cli
    mullvad-vpn
    pulsemixer
    unstable.qbittorrent
    flyctl
    zathura
    vimiv-qt
    imagemagick
    telegram-desktop
    unstable.localsend
    unstable.obsidian
    unstable.ghostty

    (pkgs.symlinkJoin {
      name = "dbeaver";
      paths = [ pkgs.dbeaver-bin ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/dbeaver --unset WAYLAND_DISPLAY
      '';
    })

    (vscode-with-extensions.override {
      vscodeExtensions = with vscode-extensions; [
        github.copilot
        github.copilot-chat
        jnoortheen.nix-ide
        ms-python.python
        golang.go
        ms-azuretools.vscode-docker
        ms-vscode-remote.remote-ssh
      ];
    })
  ];

  programs.gnupg.agent.enable = true;

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
