{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.modules.common;
in
{
  options.modules.common = {
    enable = lib.mkEnableOption "base NixOS configuration" // { default = true; };
    autoGc = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable automatic Nix garbage collection.";
    };
    autoUpgrade = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable weekly auto-upgrade from the latest lockfile in the GitHub repo.
        Config changes are still deployed manually; this only pulls security
        updates automatically. The flake target is derived from the hostname.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # basic nix cli config
    # - enable flakes because I used them everywhere
    # - delete generations older than a month, that's plenty for rollbacks
    # - auto-optimise-store sounds good too
    nix = {
      package = pkgs.nixVersions.stable;
      extraOptions = ''
        experimental-features = nix-command flakes
      '';
      settings.trusted-users = [ "root" "jack" ];
      settings.auto-optimise-store = true;
      settings.eval-cache = true;
    };

    nix.gc = lib.mkIf cfg.autoGc {
      automatic = cfg.autoGc;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    # Weekly auto-upgrade from GitHub. Reboots are constrained to a quiet
    # window so hosts don't restart at arbitrary times. GC is handled by the
    # shared weekly nix.gc timer above, so it's not run again here.
    system.autoUpgrade = lib.mkIf cfg.autoUpgrade {
      enable = true;
      flake = "github:jay-aye-see-kay/nixfiles#${config.networking.hostName}";
      dates = "Sun 03:00";
      randomizedDelaySec = "30min";
      allowReboot = true;
      rebootWindow = {
        lower = "03:00";
        upper = "05:00";
      };
    };

    # nix search nixpkgs <blah> won't download nixpkgs every time!
    nix.registry.nixpkgs.flake = inputs.nixpkgs;
    # alter nixPath so legacy commands like nix-shell can find nixpkgs.
    nix.nixPath = [ "nixpkgs=/etc/channels/nixpkgs" "nixos-config=/etc/nixos/configuration.nix" "/nix/var/nix/profiles/per-user/root/channels" ];
    environment.etc."channels/nixpkgs".source = inputs.nixpkgs.outPath;

    # this should already be set in flake.nix, but I needed it here too once?
    nixpkgs.config.allowUnfree = true;

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
  };
}
