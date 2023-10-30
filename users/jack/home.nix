{ pkgs, lib, ... }:
let
  ifDarwin = lib.mkIf pkgs.stdenv.isDarwin;
  darwinOnlyPackages = with pkgs; [
    aws-vault
    istioctl
    jdk8
    rtx
    jira-cli-go
  ];
  linuxOnlyPackages = with pkgs; [
    awscli2
    arandr
    gparted
    easyeffects
    imv
    mpv
    pdfarranger
    prusa-slicer
    syncthing
    unstable.calibre

    clang # comes with xcode, things expect to use that version

    # use rustup on mac (because netskope)
    unstable.rustc
    unstable.rustfmt
    unstable.cargo-edit
    unstable.cargo
    unstable.clippy

    # use yarn installed pnpm on work laptop
    nodePackages_latest.pnpm

    # use the script installed version on mac (to keep in sync others at work)
    unstable.devbox
  ];
in
{
  imports = [
    ./fish.nix
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    RIPGREP_CONFIG_PATH = "$HOME/.config/ripgreprc";
    DIRENV_LOG_FORMAT = "";
  };

  xdg.configFile."ripgreprc".text = ''
    --hidden
    --ignore
  '';

  home.packages = with pkgs;
    [
      neovim
      gh
      manix
      trash-cli
      (python3.withPackages (ps: [ ps.ipykernel ]))
      gnupg

      unstable.kubectl

      nodejs
      yarn

      just
      go

      exercism
      unstable.yt-dlp
      ffmpeg

      (writeShellScriptBin
        "git-guess-default-branch"
        (builtins.readFile ../../scripts/guess-default-branch.sh))
    ]
    ++ (if pkgs.stdenv.isLinux then linuxOnlyPackages else darwinOnlyPackages);

  programs = {
    home-manager.enable = true;

    direnv.enable = true;
    direnv.nix-direnv.enable = true;

    zoxide.enable = true;
    zoxide.enableFishIntegration = true;

    fzf.enable = true;
    fzf.enableFishIntegration = true;

    starship.enable = true;
    starship.enableFishIntegration = true;

    navi.enable = true;
    navi.enableFishIntegration = true;

    alacritty = {
      enable = true;
      settings = {
        font.size = if pkgs.stdenv.isLinux then 12 else 14;
        font.normal.family = ifDarwin "FiraMono Nerd Font Mono";
        # Spread additional padding evenly around the terminal content.
        window.dynamic_padding = true;
        # Make `Option` key behave as `Alt` (macOS only):
        window.option_as_alt = "OnlyRight";

        key_bindings = [
          # Don't quit on Cmd-W it's annoying
          # Unfortunately it will still quit on Cmd-Q and this can't be disabled, see https://github.com/alacritty/alacritty/issues/6136
          { key = "W"; mods = "Command"; action = "None"; }

          # https://stackoverflow.com/a/42461580
          { key = "Return"; mods = "Shift"; chars = ''\x1b[13;2u''; }
          { key = "Return"; mods = "Control"; chars = ''\x1b[13;5u''; }
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
