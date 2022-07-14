{ config, pkgs, lib, ... }:
let
  ifLinux = lib.mkIf pkgs.stdenv.isLinux;
  darwinOnlyPackages = [ ];
  linuxOnlyPackages = with pkgs; [
    arandr
    helvum
    imv
    lsof
    mpv
    nextcloud-client
    gparted
    pdfarranger
    unzip
  ];
in
{
  imports = [
    # WIP better firefox defaults
    # ./firefox.nix
  ];

  home.packages = with pkgs; [
    syncthing
    python3Full
    fnm
    htop
    jq
    nodejs
    ripgrep
    tldr
    tree
    yarn
    yq
    rustc
    rustfmt
    cargo-edit
    clang
    cargo
    clippy
    rust-analyzer
    entr
    youtube-dl
    exercism
  ] ++ (
    if pkgs.stdenv.isLinux then
      linuxOnlyPackages
    else
      darwinOnlyPackages
  );

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
    alacritty.settings = ifLinux {
      font.size = 8;
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
        init.defaultBranch = "master";
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
        brt = "!git for-each-ref refs/heads --color=always --sort -committerdate --format='%(HEAD)%(color:reset) %(color:yellow)%(refname:short)%(color:reset) %(contents:subject) %(color:green)(%(committerdate:relative))%(color:blue) <%(authorname)>'";
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
