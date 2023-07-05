{ config, pkgs, ... }:
let
  inherit (pkgs.stdenv) isDarwin;
in
{
  programs.fish = {
    enable = true;

    shellAbbrs = {
      _ = "sudo";
      g = "git";
      gs = "git status";
      gpr = "git pull --rebase";
      gpu = "git push -u";
      g- = "git checkout -";
      s = "systemctl";
      j = "just";
      e = "nvim";
      v = "nvim";
      y = "yarn";
      p = "pnpm";
      d = "docker";
      dc = "docker-compose";
      dcu = "docker-compose up -d";
      dcd = "docker-compose down";
      "~" = "cd ~";
      "-" = "cd -";
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "....." = "cd ../../../..";
    };

    functions = {
      take = {
        description = "Make a directory and cd into it";
        body = ''mkdir -p "$argv[1]"; and cd "$argv[1]"'';
      };
      notify = {
        description = "Pass all args as a system notification";
        body =
          if isDarwin then ''osascript -e "display notification \"$argv\" with title \"From terminal\""''
          else ''notify-send "from terminal" $argv'';
      };
    };

    shellAliases = {
      sizes = "du -csh * | sort -h";
      whoslistening =
        if isDarwin then "lsof -P -i TCP -s TCP:LISTEN" else "ss -lntup";
      vwy = "nvim -c LogbookYesterday";
      vwt = "nvim -c LogbookToday";
      vg = ''nvim -c "Git | wincmd k | q"'';
      pbc = if isDarwin then "pbcopy" else "wl-copy";
      pbp = if isDarwin then "pbpaste" else "wl-paste";
    };

    shellInit = ''
      # suppress default greeting
      set -U fish_greeting

      # use bash default to edit line in vim
      bind \cx\ce edit_command_buffer


      # language env set up
      fish_add_path "$HOME/.local/bin" # pip
      fish_add_path "$HOME/.poetry/bin" # poetry
      fish_add_path "(ruby -e 'puts Gem.user_dir')/bin" # ruby
      fish_add_path "$HOME/.npm_global/bin" # npm
      fish_add_path "$HOME/.yarn/bin" # yarn
      fish_add_path "$HOME/.cargo/bin" # rust
      fish_add_path "$HOME/.emacs.d/bin" # doom/emacs
      '' + (if isDarwin then ''
        ${pkgs.rtx}/bin/rtx activate fish | source
      '' else "");

      plugins = [
        # weird syntax required to use nixpkgs plugins in HM
        # see: https://nixos.wiki/wiki/Fish#Home_Manager
        { inherit (pkgs.fishPlugins.done) name src; }
        { inherit (pkgs.fishPlugins.foreign-env) name src; }
      ];

    loginShellInit =
      if isDarwin then ''
        if test -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
          fenv source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
        end

        if test -e /nix/var/nix/profiles/default/etc/profile.d/nix.sh
          fenv source /nix/var/nix/profiles/default/etc/profile.d/nix.sh
        end
      '' else "";
  };
}
