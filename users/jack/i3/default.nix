{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    brightnessctl
    dmenu
    i3lock
    sway-launcher-desktop
    xclip
    i3status-rust
  ];

  xdg.configFile."i3/config".source = ./i3-config;
  xdg.configFile."i3status-rust/config.toml".source = ./i3status-rust-config.toml;
}
