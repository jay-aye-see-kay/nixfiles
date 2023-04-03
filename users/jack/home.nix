{ config, pkgs, lib, ... }:
let
  ifLinux = lib.mkIf pkgs.stdenv.isLinux;
  ifDarwin = lib.mkIf pkgs.stdenv.isDarwin;
  darwinOnlyPackages = with pkgs; [
    aws-vault
    istioctl
    jdk8
    unstable.nodePackages.snyk
  ];
  linuxOnlyPackages = with pkgs; [
    awscli2
    arandr
    beekeeper-studio
    gparted
    easyeffects
    imv
    mpv
    pdfarranger
    prusa-slicer
    unstable.anki-bin
    syncthing
    unstable.calibre

    clang # comes with xcode, things expect to use that version

  ];
in
{
  imports = [ ];

  home.sessionVariables = {
    EDITOR = "nvim";
    RIPGREP_CONFIG_PATH = "$HOME/.config/ripgreprc";
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

      customNodePackages."aws-cdk-1.x"
      unstable.nodePackages.cdk8s-cli
      unstable.kubectl

      nodejs-16_x
      (yarn.override { nodejs = nodejs-16_x; })
      nodePackages_latest.pnpm
      customNodePackages."@fsouza/prettierd"

      just
      go

      rustc
      cargo-edit
      cargo
      clippy
      exercism
      unstable.yt-dlp
      ffmpeg

      (writeShellScriptBin
        "git-guess-default-branch"
        (builtins.readFile ../../scripts/guess-default-branch.sh))
    ]
    ++ (if pkgs.stdenv.isLinux then linuxOnlyPackages else darwinOnlyPackages);

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  programs = {
    home-manager.enable = true;

    zoxide.enable = true;
    zoxide.enableFishIntegration = true;

    fzf.enable = true;
    fzf.enableFishIntegration = true;

    starship.enable = true;
    starship.enableFishIntegration = true;

    alacritty.enable = true;
    alacritty.settings.font.size = if pkgs.stdenv.isLinux then 8 else 14;
    alacritty.settings.font.normal.family = ifDarwin "FuraMono Nerd Font Mono";
    # Spread additional padding evenly around the terminal content.
    alacritty.settings.window.dynamic_padding = true;
    # Window decorations -> none: Neither borders nor title bar
    alacritty.settings.window.decorations = "none";
    # Make `Option` key behave as `Alt` (macOS only):
    alacritty.settings.window.option_as_alt = "OnlyRight";

    alacritty.settings.key_bindings = [
      # Don't quit on Cmd-W it's annoying
      # Unfortunately it will still quit on Cmd-Q and this can't be disabled, see https://github.com/alacritty/alacritty/issues/6136
      { key = "W"; mods = "Command"; action = "None"; }

      # https://stackoverflow.com/a/42461580
      { key = "Return"; mods = "Shift"; chars = ''\x1b[13;2u''; }
      { key = "Return"; mods = "Control"; chars = ''\x1b[13;5u''; }
    ];

    # from: https://github.com/mcchrish/zenbones.nvim/blob/main/extras/alacritty/zenbones_light.yml
    # converted to json in vim with `:'<,'>!yq`
    alacritty.settings.colors = builtins.fromJSON (builtins.readFile ./alacritty-colors.json);

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
        delta.light = true;
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
