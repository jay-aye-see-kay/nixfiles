{ config, pkgs, lib, ... }:
let
  ifLinux = lib.mkIf pkgs.stdenv.isLinux;
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
    polymc # minecraft launcher, it probably works on mac, but I don't want it there
    unzip
  ];
in
{
  imports = [
    ./macos-spotlight-fix.nix
    # WIP better firefox defaults
    # ./firefox.nix
  ];

  home.packages = with pkgs;
    [
      neovim
      # === neovim stuff
      fzf
      nodejs
      stylua

      # language servers
      nodePackages.bash-language-server
      nodePackages.dockerfile-language-server-nodejs
      nodePackages.pyright
      nodePackages.typescript
      nodePackages.typescript-language-server
      nodePackages.vim-language-server
      nodePackages.vscode-langservers-extracted
      nodePackages.yaml-language-server
      rnix-lsp
      rubyPackages.solargraph
      rust-analyzer
      sumneko-lua-language-server
      # ===


      (python3.withPackages (ps: [ ps.ipykernel ]))
      nodePackages.pyright
      black

      customNodePackages."aws-cdk-1.x"
      unstable.nodePackages.cdk8s-cli
      unstable.kubectl

      aspell
      aspellDicts.en

      shfmt
      fd
      go
      gopls
      godef
      nodePackages.prettier
      awscli2
      atool
      syncthing
      nodePackages.pnpm
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
    alacritty.settings.font.size = if pkgs.stdenv.isLinux then 8 else 16;

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
        github.user = "jay-aye-see-kay";
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
