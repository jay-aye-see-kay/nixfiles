{ config, pkgs, ... }:
{
  home.pointerCursor = {
      name = "Adwaita";
      package = pkgs.gnome.adwaita-icon-theme;
      size = 24;
      x11 = {
        enable = true;
        defaultCursor = "Adwaita";
      };
    };

  xdg.configFile."sway/config".source = ./config;
  xdg.configFile."i3status-rust/config.toml".source = ./i3status-rust-config.toml;
}
