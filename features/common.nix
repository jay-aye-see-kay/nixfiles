{ pkgs, inputs, ... }:
{
  # basic nix cli config
  # - enable flakes because I used them everywhere
  # - delete generations older than a month, that's plenty for rollbacks
  # - auto-optimise-store sounds good too
  nix = {
    package = pkgs.nixVersions.stable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    settings.trusted-users = [ "root" "jack" ];
    settings.auto-optimise-store = true;
  };

  # nix search nixpkgs <blah> won't download nixpkgs every time!
  nix.registry.nixpkgs.flake = inputs.nixpkgs;
  # alter nixPath so legacy commands like nix-shell can find nixpkgs.
  nix.nixPath = [ "nixpkgs=/etc/channels/nixpkgs" "nixos-config=/etc/nixos/configuration.nix" "/nix/var/nix/profiles/per-user/root/channels" ];
  environment.etc."channels/nixpkgs".source = inputs.nixpkgs.outPath;

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
