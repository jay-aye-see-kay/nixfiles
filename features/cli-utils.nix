# WIP: collect all my "core" cli tools, describe then
# install them on all hosts from here
{ pkgs, ... }: with pkgs;
let
  platformSpecificPackages = if stdenv.isLinux then [
    lsof # list open files
    hdparm # query hard drive info
    pciutils # provides lspci
    parted # partition disks
    progress # show progress of running processes
    powertop
    git # mac+hm doesn't like having this twice?? idk it's fine on linux
  ] else [
  ];
in
platformSpecificPackages ++ [
  # shells
  bash
  fish
  nushell

  # working with json
  jq # query json
  yq # jq for yaml
  jid # incrementally narrow json
  jiq # jid with jq syntax
  jc # parse common cli outputs to json
  gron # expands out json to make it greppable

  # search
  fd
  fzf
  ripgrep
  ripgrep-all

  # unix-y "extensions"
  pv # progress of pipes?
  duf # a "better" df
  du-dust # a "better" du
  tree # view directory and sub-dirs as tree
  entr # watch files and re-run a command
  pwgen
  nmap
  wget

  tldr # sometimes better docs
  visidata

  # tools?
  just
  atool # uncompress or compress common formats with a common interface
  unzip

  # dashboards
  htop
  btop

  # measuring
  hyperfine
  tokei
  stress
]
