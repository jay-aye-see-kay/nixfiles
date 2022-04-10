{ config, pkgs, ... }:
{
  # make X 1.5x scale and stop screen tearing
  services.xserver = {
    dpi = 144;
    videoDrivers = [ "modesetting" ];
    useGlamor = true;
  };
  services.picom = {
    enable = true;
    vSync = true;
    backend = "glx";
    inactiveOpacity = 0.9;
  };

  # basic xfce+i3 setup from the NixOS wiki
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
