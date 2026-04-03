{ config, pkgs, ... }:
let
  publicKeys = import ../../publicKeys.nix;
in
{
  imports = [
    ./hardware.nix
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sdb";

  networking.hostName = "innie";

  time.timeZone = "Australia/Melbourne";
  i18n.defaultLocale = "en_AU.UTF-8";

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  users.users.jack = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      publicKeys.tuiJack
      publicKeys.deskJack
    ];
  };

  programs.fish.enable = true;

  # Allow passwordless sudo for wheel group (for remote deploys)
  security.sudo.wheelNeedsPassword = false;

  # Auto-upgrade weekly from GitHub
  # Config changes are deployed manually from tui, but security updates
  # are pulled automatically from the latest lockfile in the repo.
  system.autoUpgrade = {
    enable = true;
    flake = "github:jay-aye-see-kay/nixfiles#innie";
    dates = "Sun 03:00";
    randomizedDelaySec = "30min";
    allowReboot = true;
  };

  # NEVER CHANGE THIS
  system.stateVersion = "25.11"; # Did you read the comment?
}
