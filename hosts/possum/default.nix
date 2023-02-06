{ pkgs, ... }:
let
  publicKeys = import ../../publicKeys.nix;
in
{
  imports = [
    ./hardware.nix
    ./services.nix
  ];

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  boot.cleanTmpDir = true;
  zramSwap.enable = true;
  networking.hostName = "possum";
  networking.domain = "";

  environment.systemPackages = with pkgs; [
    git
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
