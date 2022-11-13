{ config, pkgs, lib, ... }: {
  home.packages = with pkgs; [
    wev
    firefox
    pulseaudio # system is using pipewire, but we have the binary for `pactl`
    playerctl
    i3status-rust
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
  xdg.configFile."i3status-rust/config.toml".source = ./i3status-rust-config.toml;
}
