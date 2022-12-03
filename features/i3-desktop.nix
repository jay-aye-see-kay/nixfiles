{ config, pkgs, ... }:
{
  # make X 1.5x scale and stop screen tearing
  services.xserver = {
    dpi = 144;
    videoDrivers = [ "modesetting" ];
  };
  services.picom = {
    enable = true;
    vSync = true;
    backend = "glx";
  };

  # basic i3 setup from the NixOS wiki
  services.xserver = {
    enable = true;
    displayManager.defaultSession = "none+i3";
    desktopManager.xterm.enable = false;
    windowManager.i3.enable = true;
  };

  # If your settings aren't being saved for some applications (gtk3
  # applications, firefox), like the size of file selection windows, or the
  # size of the save dialog, you will need to enable dconf:
  programs.dconf.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  # auto enable external screens when added/removed (does this need any more config?)
  services.autorandr.enable = true;

  environment.systemPackages = with pkgs; [
    lxappearance
  ];
}
