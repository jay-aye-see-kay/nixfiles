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

  home.packages = [
    (pkgs.writeShellScriptBin
      "swappy-pick-window"
      ''
      # see: https://github.com/jtheoof/swappy#example-usage
      window_dimensions="$(swaymsg -t get_tree \
        | jq -r '.. | select(.pid? and .visible?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"' \
        | slurp)"
      grim -g "$window_dimensions" - | swappy -f -
      '')
  ];

  xdg.configFile."sway/config".source = ./config;
  xdg.configFile."swaylock/config".source = ./swaylock-config;
  xdg.configFile."swappy/config".source = ./swappy-config;
  xdg.configFile."i3status-rust/config.toml".source = ./i3status-rust-config.toml;
}
