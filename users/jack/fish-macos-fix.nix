{ lib, ... }:
{
  programs.fish = {
    shellAliases = {
      whoslistening = lib.mkForce "lsof -P -i TCP -s TCP:LISTEN";
      pbc = lib.mkForce "pbcopy";
      pbp = lib.mkForce "pbpaste";
    };

    shellInit = ''
      set -x ANDROID_HOME "$HOME/Library/Android/Sdk"
      fish_add_path \
        "$ANDROID_HOME/emulator" \
        "$ANDROID_HOME/tools" \
        "$ANDROID_HOME/tools/bin" \
        "$ANDROID_HOME/platform-tools"
    '';

    loginShellInit = ''
      if test -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
        fenv source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
      end

      if test -e /nix/var/nix/profiles/default/etc/profile.d/nix.sh
        fenv source /nix/var/nix/profiles/default/etc/profile.d/nix.sh
      end
    '';
  };
}
