{ config, pkgs, ... }:
{
  environment.pathsToLink = [ "/libexec" ];
  environment.systemPackages = with pkgs; [
    gnome.dconf-editor
    gsettings-desktop-schemas
    gtk-engine-murrine
    gtk3
    gtk_engines
    lxappearance
    mojave-gtk-theme
    whitesur-icon-theme
    polkit_gnome
  ];

  programs.sway.enable = true;
  programs.dconf.enable = true;
  services.gnome.at-spi2-core.enable = true;

  # nixos env variable enabling ozone for native scaling on wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # lazy replacement for a display manager
  environment.loginShellInit = ''
    if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
      exec sway
    fi
  '';
}
