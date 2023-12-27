{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    prismlauncher # minecraft launcher
    unstable.openra
  ];

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
  };
}
