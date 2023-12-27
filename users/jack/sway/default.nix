{ pkgs, ... }:
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

    (pkgs.writeShellScriptBin
      "sway-scale-focused-window"
      ''
        # ensure binaries are available
        bc="${pkgs.bc}/bin/bc"
        jq="${pkgs.jq}/bin/jq"

        # parse input arg
        scale_change="$1"

        # get current focused display and scale
        active_output=$(swaymsg -t get_outputs | $jq -r '.[] | select(.focused == true) | .name')
        current_scale=$(swaymsg -t get_outputs | $jq -r ".[] | select(.name == \"$active_output\") | .scale")

        # set new scale
        new_scale=$(echo "$current_scale + $scale_change" | $bc)
        swaymsg "output $active_output scale $new_scale"
      '')
  ];

  xdg.configFile = {
    "sway/config".source = ./config;
    "swaylock/config".source = ./swaylock-config;
    "swappy/config".source = ./swappy-config;
    "i3status-rust/config.toml".source = ./i3status-rust-config.toml;
  };
}
