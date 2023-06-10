{ config, pkgs, ... }:
{
  xdg.configFile."sway/config".source = ./config;
  xdg.configFile."i3status-rust/config.toml".source = ./i3status-rust-config.toml;
}
