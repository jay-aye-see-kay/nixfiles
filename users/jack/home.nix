{ pkgs, pkgs-unstable, lib, ... }:
let
  ifDarwin = lib.mkIf pkgs.stdenv.isDarwin;
  darwinOnlyPackages = [
    pkgs.granted
    pkgs-unstable.mise
    pkgs.jira-cli-go
    pkgs.google-cloud-sdk
  ];
  linuxOnlyPackages = [
    pkgs.awscli2
    pkgs.arandr
    pkgs.gparted
    pkgs.easyeffects
    pkgs.imv
    pkgs.mpv
    pkgs.pdfarranger
    pkgs.prusa-slicer
    pkgs.syncthing
    pkgs-unstable.calibre
    pkgs-unstable.opencode
    pkgs-unstable.devbox

    pkgs.clang # comes with xcode, things expect to use that version
  ];
in
{
  imports = [
    ./fish.nix
  ];

  home.sessionVariables = {
    RIPGREP_CONFIG_PATH = "$HOME/.config/ripgreprc";
    DIRENV_LOG_FORMAT = "";
    # EDITOR is set by devtools module if enabled
  };

  xdg.configFile."ripgreprc".text = ''
    --hidden
    --ignore
  '';

  home.packages = with pkgs;
    [
      gh
      manix
      trash-cli
      gnupg

      pkgs-unstable.yt-dlp
      ffmpeg

      (writeShellScriptBin
        "git-guess-default-branch"
        (builtins.readFile ../../scripts/guess-default-branch.sh))
    ]
    ++ (if pkgs.stdenv.isLinux then linuxOnlyPackages else darwinOnlyPackages);
  
  # Development tools (LSPs, formatters, runtimes, etc) are in ../features/devtools.nix
  # Enable per-host in flake.nix by setting features.devtools.enable = true;

  programs = {
    home-manager.enable = true;

    direnv.enable = true;
    direnv.nix-direnv.enable = true;

    zoxide.enable = true;
    zoxide.enableFishIntegration = true;

    fzf.enable = true;
    fzf.enableFishIntegration = false;

    starship.enable = true;
    starship.enableFishIntegration = true;
    starship.settings = {
      gcloud.disabled = true;
    };

    navi.enable = true;
    navi.enableFishIntegration = true;

    atuin.enable = true;
    atuin.settings = {
      enter_accept = false;
      daemon.enabled = pkgs.stdenv.isLinux; # quick hack
    };
    atuin.flags = [
      "--disable-up-arrow"
    ];
    atuin.daemon.enable = pkgs.stdenv.isLinux;

    alacritty = {
      enable = true;
      settings = {
        font.size = if pkgs.stdenv.isLinux then 12 else 14;
        font.normal.family = ifDarwin "FiraMono Nerd Font Mono";
        # Spread additional padding evenly around the terminal content.
        window.dynamic_padding = true;
        # Make `Option` key behave as `Alt` (macOS only):
        window.option_as_alt = "OnlyRight";

        keyboard.bindings = [
          # Don't quit on Cmd-W it's annoying
          # Unfortunately it will still quit on Cmd-Q and this can't be disabled, see https://github.com/alacritty/alacritty/issues/6136
          { key = "W"; mods = "Command"; action = "None"; }
          # shift enter is newline
          { key = "Return"; mods = "Shift"; chars = "\n"; }
        ];

        # from: https://github.com/catppuccin/alacritty/blob/main/catppuccin-mocha.yml
        # converted to json in vim with `:'<,'>!yq`
        colors = builtins.fromJSON (builtins.readFile ./alacritty-colors.json);
      };
    };

    git = {
      enable = true;
      package = pkgs.gitAndTools.gitFull;
      delta.enable = true;
      userName = "Jack Rose";
      userEmail = "user@jackrose.co.nz";
      extraConfig = {
        pull.rebase = false;
        push.default = "current";
        init.defaultBranch = "main";
        github.user = "jay-aye-see-kay";
        url."ssh://git@github.com/".insteadOf = "https://github.com/";
      };
      aliases = {
        aa = "add .";
        ci = "commit";
        cia = "commit -a";
        co = "checkout";
        cob = "checkout -b";
        cod = "checkout develop";
        com = ''!git checkout "$(git guess-default-branch)"'';
        gdb = "guess-default-branch";
        df = "diff";
        dfs = "diff --staged";
        st = "status";
        pu = "push";
        pfl = "push --force-with-lease";
        pop = "stash pop";
        unstage = "reset HEAD --";
        brt =
          "!git for-each-ref refs/heads --color=always --sort -committerdate --format='%(HEAD)%(color:reset) %(color:yellow)%(refname:short)%(color:reset) %(contents:subject) %(color:green)(%(committerdate:relative))%(color:blue) <%(authorname)>'";
        uncommit = "reset --soft HEAD~1";
        recommit = "commit --amend --no-edit";
        changeset-recommit-branch = "git fetch && git checkout changeset-release/master && git reset --hard origin/changeset-release/master && git commit --amend --no-edit && git push --force-with-lease";
      };
      ignores = [
        ".vim"
        "*.swp"
        "*.swo"
        "*.swn"
        "tags"
        ".node-version"
        ".python-version"
        ".npmrc"
      ];
    };
  };
}
