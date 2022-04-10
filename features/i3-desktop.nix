{ config, pkgs, ... }:
{
  services.xserver.dpi = 144;
  services.xserver.videoDrivers = [ "modesetting" ];
  services.xserver.useGlamor = true;
  services.picom = {
    enable = true;
    vSync = true;
  };

  services.xserver = {
    enable = true;
    displayManager.defaultSession = "xfce";
    desktopManager = {
      xterm.enable = false;
      xfce = {
        enable = true;
        noDesktop = true;
        enableXfwm = false;
      };
    };
    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        dmenu
        i3status-rust
        i3lock
      ];
    };
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;
}
