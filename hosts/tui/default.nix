{ config, pkgs, ... }:
let
  publicKeys = import ../../publicKeys.nix;
in
{
  imports = [ ./hardware.nix ];

  nix = {
    package = pkgs.nixFlakes; # or versioned attributes like nix_2_7
    extraOptions = ''
      experimental-features = nix-command flakes
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

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp0s31f6.useDHCP = true;
  networking.interfaces.wlp2s0.useDHCP = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_AU.UTF-8";

  services.xserver.dpi = 144;
  services.xserver.videoDrivers = [ "modesetting" ];
  services.xserver.useGlamor = true;
  services.picom = {
    enable = true;
    vSync = true;
  };

  services.xserver = {
    enable = true;
    displayManager.defaultSession = "xfce";
    desktopManager = {
      xterm.enable = false;
      xfce = {
        enable = true;
        noDesktop = true;
        enableXfwm = false;
      };
    };
    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        dmenu
        i3status-rust
        i3lock
      ];
    };
  };


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
    media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  users.users.jack = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [ "wheel" "docker" "networkmanager" ];
    openssh.authorizedKeys.keys = [
      publicKeys.x1aJack
      publicKeys.deskJack
    ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    chromium
    lm_sensors
    _1password
    _1password-gui
    age
    alacritty
    btop
    fd
    firefox
    git
    hdparm
    neovim
    nmap
    parted
    pciutils # provides lspci
    powertop
    progress
    pwgen
    ripgrep
    sops
    stress
    tldr
    wget
  ];

  fonts.fonts = with pkgs; [
    font-awesome
    noto-fonts
    noto-fonts-emoji
    fira-code
    fira-code-symbols
  ];

  services.interception-tools = {
    enable = true;
    plugins = [ pkgs.interception-tools-plugins.dual-function-keys ];
    udevmonConfig =
      let
        dualFnConfig = builtins.toFile "dual-caps.yaml" (builtins.toJSON {
          TIMING = {
            TAP_MILLISEC = 200;
            DOUBLE_TAP_MILLISEC = 150;
          };
          MAPPINGS = [{
            KEY = "KEY_CAPSLOCK";
            TAP = "KEY_ESC";
            HOLD = "KEY_LEFTCTRL";
          }];
        });
      in
      builtins.toJSON [{
        JOB = "${pkgs.interception-tools}/bin/intercept -g $DEVNODE"
          + " | ${pkgs.interception-tools-plugins.dual-function-keys}/bin/dual-function-keys -c ${dualFnConfig}"
          + " | ${pkgs.interception-tools}/bin/uinput -d $DEVNODE";
        DEVICE = {
          EVENTS = {
            EV_KEY = [ "KEY_CAPSLOCK" ];
          };
        };
      }];
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ ];
  networking.firewall.allowedUDPPorts = [ ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}

