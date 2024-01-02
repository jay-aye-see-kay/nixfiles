{ pkgs, ... }: {
  users.users.jack = {
    home = "/Users/jack";
    shell = pkgs.fish;
  };

  programs.fish.enable = true;
  environment.shells = [ pkgs.fish ];
  environment.variables = {
    NIX_SSL_CERT_FILE = "/Library/Application Support/Netskope/STAgent/data/nscacert_combined.pem";
  };
  environment.systemPackages = [ pkgs.hello pkgs.alacritty ];

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";
}



# PREV /etc/nix/nix.conf
# Generated by https://github.com/DeterminateSystems/nix-installer, version 0.14.0.
# trusted-users = root jack
# build-users-group = nixbld
# experimental-features = nix-command flakes repl-flake
# bash-prompt-prefix = (nix:$name)\040
# max-jobs = auto
# ssl-cert-file = /Library/Application Support/Netskope/STAgent/data/nscacert_combined.pem
# extra-nix-path = nixpkgs=flake:nixpkgs