{ config, pkgs, ... }:
let
  publicKeys = import ../../publicKeys.nix;
  authorizedKeys = with publicKeys; [
    unknown1
    tuiJack
    iSH
    keaJack
  ];
in
{
  imports = [
    ./hardware.nix
    ./services.nix
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  networking.hostName = "honey";
  time.timeZone = "Australia/Melbourne";

  users.users.jack = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = authorizedKeys;
  };

  users.users.root = {
    openssh.authorizedKeys.keys = authorizedKeys;
  };

  users.defaultUserShell = pkgs.fish;
  programs.fish.enable = true;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  services.openssh.enable = true;
  services.qemuGuest.enable = true;

  # Allow passwordless sudo for wheel group (for remote deploys)
  security.sudo.wheelNeedsPassword = false;

  # Auto-upgrade weekly from GitHub
  # Config changes are deployed manually with `just honey-deploy` (builds on
  # honey itself, so it can be run from any host), but security updates are
  # pulled automatically from the latest lockfile in the repo.
  system.autoUpgrade = {
    enable = true;
    flake = "github:jay-aye-see-kay/nixfiles#honey";
    dates = "Sun 03:00";
    randomizedDelaySec = "30min";
    allowReboot = true;
    runGarbageCollection = true;
    rebootWindow = {
      lower = "03:00";
      upper = "05:00";
    };
  };

  # NEVER CHANGE THIS
  system.stateVersion = "25.05"; # Did you read the comment?
}
