# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "moa";

  # Set your time zone.
  time.timeZone = "Australia/Melbourne";
  # Select internationalisation properties.
  i18n.defaultLocale = "en_AU.UTF-8";

  # SPICE!
  services.spice-vdagentd.enable = true;

  services.gnome.gnome-keyring.enable = true;
  programs.fish.enable = true;
  programs.plotinus.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jack = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [ "wheel" "docker" "networkmanager" "video" ];
  };

  environment.variables = {
    # Because we're a VM, we don't have a GPU which messes with alacritty, this resolves that
    LIBGL_ALWAYS_SOFTWARE = "1";
    # otherwise cursors are upside down
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  virtualisation.docker.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    alacritty
    docker-compose
    firefox
    home-manager
    neovim
    zathura
    valgrind
    massif-visualizer
  ];

  services.openssh.enable = true;
  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}

