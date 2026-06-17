{ config, lib, pkgs, ... }:
let
  cfg = config.modules.homebrew;
in
{
  options.modules.homebrew = {
    enable = lib.mkEnableOption "Homebrew Brewfile management (macOS only)";
  };

  # Mac-only: avoid nix-darwin (suspected bad interactions with MDM/security
  # software). The whole config is guarded by isDarwin so it is a no-op on NixOS.
  config = lib.mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
    # Symlink the repo Brewfile into the home dir for convenient manual
    # `brew bundle` runs. The activation below uses the in-repo copy directly.
    home.file.".Brewfile".source = ./Brewfile;

    # Run `brew bundle` on every switch. `--cleanup` uninstalls anything not
    # listed in the Brewfile, so removing a line here removes it on the next
    # switch. `--no-upgrade` keeps activation fast (run `brew upgrade` manually).
    # @see: https://github.com/Homebrew/homebrew-bundle
    home.activation.brewBundle = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -e
      # Detect the Homebrew prefix (Apple Silicon first, then Intel).
      if [ -x /opt/homebrew/bin/brew ]; then
        BREW_BIN="/opt/homebrew/bin/brew"
      elif [ -x /usr/local/bin/brew ]; then
        BREW_BIN="/usr/local/bin/brew"
      else
        BREW_BIN=""
      fi

      if [ -n "$BREW_BIN" ]; then
        export PATH="$(dirname "$BREW_BIN"):$PATH"
        $DRY_RUN_CMD "$BREW_BIN" bundle --file=${./Brewfile} --cleanup --no-upgrade
      else
        echo "homebrew module: brew not found, skipping brew bundle"
      fi
    '';
  };
}
