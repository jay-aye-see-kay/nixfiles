{ config, lib, pkgs, ... }:

with lib;

{
  options.features.games = {
    enable = mkEnableOption "games and gaming-related packages";
  };

  config = mkIf config.features.games.enable {
    environment.systemPackages = with pkgs; [
      prismlauncher # minecraft launcher
    ];

    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };
  };
}
