{ config, lib, pkgs, ... }:
let
  cfg = config.modules.gui-utils;
in
{
  options.modules.gui-utils = {
    enable = lib.mkEnableOption "GUI utilities for hardware information";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      libva-utils # provides vainfo
      clinfo # provides clinfo (opencl)
      vulkan-tools # provides vulkaninfo
    ];
  };
}
