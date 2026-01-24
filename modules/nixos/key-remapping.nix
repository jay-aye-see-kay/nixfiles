{ config, lib, pkgs, ... }:
let
  cfg = config.modules.key-remapping;
in
{
  options.modules.key-remapping = {
    enable = lib.mkEnableOption "key remapping (Caps Lock to Esc/Ctrl)";
  };

  config = lib.mkIf cfg.enable {
    services.interception-tools = {
      enable = true;
      plugins = [ pkgs.interception-tools-plugins.dual-function-keys ];
      udevmonConfig =
        let
          dualFnConfig = builtins.toFile "dual-caps.yaml" (builtins.toJSON {
            TIMING = {
              TAP_MILLISEC = 200;
              DOUBLE_TAP_MILLISEC = 150;
            };
            MAPPINGS = [{
              KEY = "KEY_CAPSLOCK";
              TAP = "KEY_ESC";
              HOLD = "KEY_LEFTCTRL";
            }];
          });
        in
        builtins.toJSON [{
          JOB = "${pkgs.interception-tools}/bin/intercept -g $DEVNODE"
            + " | ${pkgs.interception-tools-plugins.dual-function-keys}/bin/dual-function-keys -c ${dualFnConfig}"
            + " | ${pkgs.interception-tools}/bin/uinput -d $DEVNODE";
          DEVICE = {
            EVENTS = {
              EV_KEY = [ "KEY_CAPSLOCK" ];
            };
          };
        }];
    };
  };
}
