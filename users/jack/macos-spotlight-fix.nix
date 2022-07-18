# On macOS copy applications from the default location
# `~/.nix-profile/Applications` to `~/Applications` and resolove links
# while doing it because spotlight won't follow links
#
# see: https://github.com/nix-community/home-manager/issues/1341#issuecomment-778820334

{ config, pkgs, lib, ... }: {
  home.activation = lib.mkIf pkgs.stdenv.targetPlatform.isDarwin {
    copyApplications = let
      apps = pkgs.buildEnv {
        name = "home-manager-applications";
        paths = config.home.packages;
        pathsToLink = "/Applications";
      };
    in lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      baseDir="$HOME/Applications/Home Manager Apps"
      if [ -d "$baseDir" ]; then
        rm -rf "$baseDir"
      fi
      mkdir -p "$baseDir"
      for appFile in ${apps}/Applications/*; do
        target="$baseDir/$(basename "$appFile")"
        $DRY_RUN_CMD cp ''${VERBOSE_ARG:+-v} -fHRL "$appFile" "$baseDir"
        $DRY_RUN_CMD chmod ''${VERBOSE_ARG:+-v} -R +w "$target"
      done
    '';
  };
}
