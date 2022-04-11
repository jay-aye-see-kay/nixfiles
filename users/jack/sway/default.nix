{ config, lib, pkgs, ... }:
{
  home.packages = with pkgs; [
    kanshi # autorandr
    swayidle
    swaylock
    wdisplays
    wl-clipboard
    xwayland
    pkgs.unstable.swaynotificationcenter
    sirula
    waybar
  ];

  wayland.windowManager.sway = {
    enable = true;
    wrapperFeatures.gtk = true; # so that gtk works properly
    extraSessionCommands = ''
      export MOZ_ENABLE_WAYLAND=1
      export TERMINAL=${pkgs.alacritty}/bin/alacritty
    '';
  };

  wayland.windowManager.sway.config = {
    modifier = "Mod4"; # logo key
    menu = "${pkgs.sirula}/bin/sirula";
    terminal = "${pkgs.alacritty}/bin/alacritty";
    bars = [{
      position = "top";
      command = "waybar";
    }];
    startup = [
      { command = "swaync"; always = false; }
    ];
    output = {
      "*" = { scale = "1.5"; };
      "eDP-1" = { position = "440 1440"; }; # builtin laptop screen
      "Dell Inc. DELL S2721QS 7FFC513" = { position = "0 0"; }; # main home screen
    };
    input = {
      "*" = { accel_profile = "adaptive"; };
      "1739:0:Synaptics_TM3289-021" = {
        middle_emulation = "disabled";
        dwt = "enabled";
        natural_scroll = "enabled";
      };
    };
    keybindings =
      let
        mod = config.wayland.windowManager.sway.config.modifier;
      in
      lib.mkOptionDefault {
        "${mod}+n" = "exec ${pkgs.unstable.swaynotificationcenter}/bin/swaync-client -t -sw";
        "${mod}+b" = "exec ${pkgs.firefox}/bin/firefox";
        "${mod}+Shift+b" = "exec ${pkgs.firefox}/bin/firefox --private-window";
        "Control+q" = "nop nop"; # only use mod+shift+q
        "${mod}+a" = "focus parent";
        "${mod}+z" = "focus child";
      };
  };

  xdg.configFile."waybar/config".source = ./waybar.json;
  xdg.configFile."waybar/style.css".source = ./waybar.css;
}

