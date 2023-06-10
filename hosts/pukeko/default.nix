{ modulesPath, pkgs, ... }:
let
  publicKeys = import ../../publicKeys.nix;
in
{
  imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
    ./services.nix
  ];

  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 2048; # MB
  }];

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

  boot.tmp.cleanOnBoot = true;
  networking.hostName = "pukeko";
  networking.domain = "";

  environment.systemPackages = with pkgs; [
    unstable.authelia
  ] ++ (import ../../features/cli-utils.nix { inherit pkgs; });

  programs.neovim = {
    enable = true;
    viAlias = true;
    defaultEditor = true;
  };

  programs.fish.enable = true;

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

  system.stateVersion = "22.11";
}
