{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    brightnessctl
    pulseaudio
    light
    playerctl
    dmenu
    i3lock
    i3status-rust
    sway-launcher-desktop
    xclip

    themechanger
    whitesur-gtk-theme
    whitesur-icon-theme
    phinger-cursors
  ];

  xdg.configFile."i3/config".source = ./i3-config;
  xdg.configFile."i3status-rust/config.toml".source = ./i3status-rust-config.toml;
}
