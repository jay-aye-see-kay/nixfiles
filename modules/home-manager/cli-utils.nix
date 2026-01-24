{ config, lib, pkgs, pkgs-unstable, ... }:
let
  cfg = config.modules.cli-utils;
in
{
  options.modules.cli-utils = {
    enable = lib.mkEnableOption "essential CLI utilities";
  };

  config = lib.mkIf cfg.enable {
    home.packages = import ../shared/cli-utils-packages.nix { inherit pkgs pkgs-unstable; };
  };
}
