{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    brightnessctl
    dmenu
    i3lock
    sway-launcher-desktop
    xclip
  ];

  xdg.configFile."i3/config".source = ./i3-config;

  programs.i3status-rust.enable = true;
  # programs.i3status-rust.bars = {};
}
