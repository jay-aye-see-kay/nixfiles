{ config, lib, pkgs, ... }:
let
  cfg = config.modules.cli-utils;
in
{
  options.modules.cli-utils = {
    enable = lib.mkEnableOption "essential CLI utilities";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = import ../shared/cli-utils-packages.nix { inherit pkgs; };
  };
}
