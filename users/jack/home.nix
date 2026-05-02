{ pkgs, pkgs-unstable, lib, config, ... }:
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
    NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global"; # so `npm -g` works
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.npm-global/bin"
  ];

  xdg.configFile."ripgreprc".text = ''
    --hidden
    --ignore
  '';

  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/nixfiles/dots/nvim";

  home.packages = with pkgs;
    [
      gh
      manix
      trash-cli
      gnupg

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

    ghostty = if pkgs.stdenv.isDarwin then { } else {
      enable = true;
      systemd.enable = true;
      settings = {
        theme = "GitHub Light Default";
      };
    };

    git = {
      enable = true;
      package = pkgs.gitFull;
      settings = {
        user.name = "Jack Rose";
        user.email = "user@jackrose.co.nz";
        pull.rebase = false;
        push.default = "current";
        init.defaultBranch = "main";
        github.user = "jay-aye-see-kay";
        url."ssh://git@github.com/".insteadOf = "https://github.com/";
        alias = {
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

    delta = {
      enable = true;
      enableGitIntegration = true;
    };
  };
}
