{ pkgs, ... }:
{
  # basic nix cli config
  # - enable flakes because I used them everywhere
  # - delete generations older than a month, that's plenty for rollbacks
  # - auto-optimise-store sounds good too
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    settings.auto-optimise-store = true;
  };

  # this should already be set in flake.nix, but I needed it here too once?
  nixpkgs.config.allowUnfree = true;

  # import standard cli utils I want everywhere, theoretically they should all be small
  # without too many deps, if they're big, they shouldn't be here
  environment.systemPackages = 
    import ./cli-utils.nix { inherit pkgs; };

  # Allow all users which are part of the group wheel to shutdown or restart, this doesn't
  # grant any new permissions it just means password entry isn't required.
  # https://nixos.wiki/wiki/Sudo
  security.sudo = {
    enable = true;
    extraRules = [{
      groups = [ "wheel" ];
      commands = [
        { options = [ "NOPASSWD" ]; command = "${pkgs.systemd}/bin/systemctl suspend"; }
        { options = [ "NOPASSWD" ]; command = "${pkgs.systemd}/bin/reboot"; }
        { options = [ "NOPASSWD" ]; command = "${pkgs.systemd}/bin/shutdown"; }
        { options = [ "NOPASSWD" ]; command = "${pkgs.systemd}/bin/poweroff"; }
      ];
    }];
  };
}
