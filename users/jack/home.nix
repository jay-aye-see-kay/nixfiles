{ config, pkgs, lib, ... }:
let
  ifLinux = lib.mkIf pkgs.stdenv.isLinux;
  ifDarwin = lib.mkIf pkgs.stdenv.isDarwin;
  darwinOnlyPackages = with pkgs; [
    unstable.nodePackages.snyk
  ];
  linuxOnlyPackages = with pkgs; [
    arandr
    beekeeper-studio
    gparted
    helvum
    easyeffects
    imv
    lsof
    mpv
    nextcloud-client
    pdfarranger
    prismlauncher # minecraft launcher, it probably works on mac, but I don't want it there
    unzip
    prusa-slicer
    unstable.anki-bin
    syncthing

    clang # comes with xcode, things expect to use that version

    # these are broken on macos, no idea why but I don't really need them
    black
    yq
    youtube-dl
  ];
in
{
  imports = [
    # WIP better firefox defaults
    # ./firefox.nix
  ];

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
      fzf
      gh
      manix
      trash-cli
      (python3.withPackages (ps: [ ps.ipykernel ]))

      # TODO: move neovim flake
      delve
      gopls
      godef
      aspell
      aspellDicts.en

      customNodePackages."aws-cdk-1.x"
      customNodePackages."@fsouza/prettierd"
      unstable.nodePackages.cdk8s-cli
      unstable.kubectl

      nodejs-16_x
      (yarn.override { nodejs = nodejs-16_x; })
      nodePackages_latest.pnpm

      just
      shfmt
      fd
      go
      nodePackages.prettier
      awscli2
      atool
      htop
      jq
      yq
      ripgrep
      tldr
      tree
      rustc
      rustfmt
      cargo-edit
      cargo
      clippy
      entr
      exercism
      tokei
      hyperfine
    ]
    ++ (if pkgs.stdenv.isLinux then linuxOnlyPackages else darwinOnlyPackages);

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  services.nextcloud-client = ifLinux {
    enable = true;
    startInBackground = true;
  };

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
        com = "checkout master";
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
