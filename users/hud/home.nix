{ config, pkgs, lib, ... }: {
  home.packages = with pkgs; [
    firefox
  ];

  programs = {
    home-manager.enable = true;

    fish.enable = true;
    fzf.enable = true;
    fzf.enableFishIntegration = true;
    starship.enable = true;
    starship.enableFishIntegration = true;
  };

  xdg.configFile."sway/config".source = ./sway-config;
}
