{ pkgs, ... }:
let
  publicKeys = import ../../publicKeys.nix;
in
{
  imports = [
    ./hardware.nix
    ./services.nix
    ../../features/cli-utils.nix
  ];

  nix = {
    package = pkgs.nixFlakes;
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

  boot.cleanTmpDir = true;
  zramSwap.enable = true;
  networking.hostName = "possum";
  networking.domain = "";

  environment.systemPackages = with pkgs; [
    git
    authelia
  ];

  users.users.jack = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [ "wheel" "docker" "networkmanager" "video" ];
    openssh.authorizedKeys.keys = [
      publicKeys.tuiJack
      publicKeys.deskJack
    ];
  };

  services.openssh.enable = true;

  networking.firewall = {
    allowedTCPPorts = [
      80 # http
      443 # https
      22000 # syncthing
    ];
    allowedUDPPorts = [
      80 # http
      443 # https
      21027 # syncthing
      22000 # syncthing
    ];
  };

  system.stateVersion = "22.05";
}
