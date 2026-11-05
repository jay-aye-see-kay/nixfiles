{ config, lib, pkgs, ... }:
let
  cfg = config.modules.rex;
  domain = "com.superlogical.rex";
in
{
  options.modules.rex = {
    enable = lib.mkEnableOption "Rex terminal multiplexer config and app settings";
  };

  config = lib.mkIf cfg.enable {
    # Lua config: keybindings and actions. Rex has no Lua API for app settings,
    # so those are managed via user defaults below.
    xdg.configFile."rex/init.lua".source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nixfiles/dots/rex/init.lua";

    # Rex app settings (Settings… window). `defaults import` merges, so
    # per-machine state in the same plist (window frames, session ids, update
    # checks, etc.) is left alone. Quit Rex before switching, or it may write
    # its in-memory values back over these.
    targets.darwin.defaults.${domain} = {
      # appearance
      "Workspace.lightThemeID" = "custom-DD1CEEE1-FC58-4929-B534-60FBCFCFBC8A";
      "Workspace.animationStyle" = "snappy";
      "Workspace.paneDensity" = "compact";
      "Workspace.showsPaneHeaders" = true;

      # terminal text
      "Workspace.terminalAllowsLigatures" = false;
      "Workspace.terminalSmoothScrolling" = true;

      # tabs and sidebar
      "Workspace.tabStyle" = "vertical";
      "Workspace.sidebarPosition" = "left";

      # app and server
      # remote control is needed for smart-splits-backend-rex's resize path
      "rex.client.remoteControl" = true;
      "rex.server.automatic-restart-enabled" = true;
      "rex.server.run-mode" = "bundled";
      "SUAutomaticallyUpdate" = true;
      "SUEnableAutomaticChecks" = true;
    };

    # Custom themes are stored as a binary (data) blob of JSON, which
    # targets.darwin.defaults can't express. The ids in the JSON are what
    # Workspace.lightThemeID/darkThemeID above refer to.
    # The theme was originally imported from Ghostty's "GitHub Light Default".
    home.activation.rexCustomThemes = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run /usr/bin/defaults write ${domain} Workspace.customThemes -data \
        "$(${pkgs.jq}/bin/jq --compact-output . ${../../dots/rex/custom-themes.json} | /usr/bin/xxd -p | tr -d '\n')"
    '';
  };
}
