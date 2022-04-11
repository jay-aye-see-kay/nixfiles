{ config, pkgs, ... }:
{
  environment.pathsToLink = [ "/libexec" ];
  environment.systemPackages = with pkgs; [
    polkit_gnome
    gtk3
  ];

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        user = "jack";
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd sway";
      };
    };
  };

  programs.sway.enable = true;
}
