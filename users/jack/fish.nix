{ pkgs, lib, ... }:
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
      gd = "git diff";
      gdm = "git diff (git merge-base (git guess-default-branch) HEAD)";
      g- = "git checkout -";
      s = "systemctl";
      j = "just";
      e = "nvim";
      v = "nvim";
      y = "yarn";
      p = "pnpm";
      d = "docker";
      k = "kubectl";
      ka = "kubectl apply -f";
      kp = "kubectl get pod";
      ki = "kubectl cluster-info";
      dc = "docker-compose";
      dcu = "docker-compose up -d";
      dcd = "docker-compose down";
      "~" = "cd ~";
      "-" = "cd -";
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "....." = "cd ../../../..";
      ni = "nix profile install nixpkgs#";
      ns = "nix shell nixpkgs#";
      ",z" = "zi";
      db = "devbox";
      dba = "devbox add";
      dbr = "devbox rm";
      dbs = "devbox services";
      dbu = "devbox services up -b";
      dbd = "devbox services down";
      dbl = "devbox services ls";
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
      # decompress using deflate algo, used in the Building Git book
      inflate = "${pkgs.pigz}/bin/pigz --decompress --zlib --stdout";

      assume = lib.mkIf isDarwin
        "source ${pkgs.grantedWithFish}/share/assume.fish";
      granted-refresh = lib.mkIf isDarwin
        "granted sso populate --sso-region us-west-2 https://cultureamp.awsapps.com/start";
    };

    shellInit = ''
      # suppress default greeting
      set -U fish_greeting

      # use bash default to edit line in vim
      bind \cx\ce edit_command_buffer

      # language env set up
      fish_add_path "$HOME/.local/bin" # pip
      fish_add_path "$HOME/.poetry/bin" # poetry
      fish_add_path "$HOME/.npm_global/bin" # npm
      fish_add_path "$HOME/.yarn/bin" # yarn
      fish_add_path "$HOME/.cargo/bin" # rust

      # source granted completions if they exist `granted completion --shell fish` to put them there
      # bit of a hack; would be nicer if we could do this the nix way
      if test -f $HOME/.config/fish/completions/granted_completer_fish.fish
          source $HOME/.config/fish/completions/granted_completer_fish.fish
      end
      set -x GRANTED_ALIAS_CONFIGURED true
    '' + (if isDarwin then ''
      ${pkgs.mise}/bin/mise activate fish | source

      if test -f $HOME/.rd/bin
          # rancher's docker binaries
          fish_add_path $HOME/.rd/bin
      end

      # homebrew stuff (generated with /opt/homebrew/bin/brew shellenv)
      #
      set -gx HOMEBREW_NO_ANALYTICS "1"
      # this part generated with /opt/homebrew/bin/brew shellenv
      #
      set -gx HOMEBREW_PREFIX "/opt/homebrew";
      set -gx HOMEBREW_CELLAR "/opt/homebrew/Cellar";
      set -gx HOMEBREW_REPOSITORY "/opt/homebrew";
      fish_add_path -gP "/opt/homebrew/bin" "/opt/homebrew/sbin";
      set -q MANPATH; and set MANPATH[1] ":$(string trim --left --chars=":" $MANPATH[1])";
      ! set -q INFOPATH; and set INFOPATH ""; set -gx INFOPATH "/opt/homebrew/share/info" $INFOPATH;
    '' else "");

    plugins = [
      # weird syntax required to use nixpkgs plugins in HM
      # see: https://nixos.wiki/wiki/Fish#Home_Manager
      { inherit (pkgs.fishPlugins.done) name src; }
      { inherit (pkgs.fishPlugins.foreign-env) name src; }
      {
        name = "pnpm-shell-completion";
        src = pkgs.fetchFromGitHub {
          owner = "g-plane";
          repo = "pnpm-shell-completion";
          rev = "v0.5.2";
          sha256 = "sha256-VCIT1HobLXWRe3yK2F3NPIuWkyCgckytLPi6yQEsSIE=";
        };
      }
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
