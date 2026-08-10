# collect all my "core" cli tools, describe then
# install them on all hosts from here
{ pkgs, ... }: with pkgs;
let
  linuxOnlyPackages = [
    lsof # list open files
    hdparm # query hard drive info
    pciutils # provides lspci
    parted # partition disks
    progress # show progress of running processes
    powertop
    git # mac+hm doesn't like having this twice?? idk it's fine on linux
    curl # use macos' built in
    ltunify # manage logitech unifying receiver dongle (linux only)
    httm # TUI for zfs snapshots
  ];

  # macOS ships BSD userland, which lacks timeout, nproc, tac, shuf,
  # numfmt, shred and GNU flags like `date -d` / `stat -c`.
  # This shadows the BSD tools with GNU versions on purpose.
  darwinOnlyPackages = [
    coreutils
  ];

  platformSpecificPackages =
    lib.optionals stdenv.isLinux linuxOnlyPackages
    ++ lib.optionals (!stdenv.isLinux) darwinOnlyPackages;
in
platformSpecificPackages ++ [
  # shells
  bashInteractive
  fish
  nushell

  # working with json
  jq # query json
  yq-go # jq for yaml
  jid # incrementally narrow json
  jiq # jid with jq syntax
  jc # parse common cli outputs to json
  gron # expands out json to make it greppable
  fx # interactive json viewer

  # search
  fd
  fzf
  ripgrep

  # unix-y "extensions"
  pv # progress of pipes?
  duf # a "better" df
  dust # a "better" du
  tree # view directory and sub-dirs as tree
  entr # watch files and re-run a command
  pwgen
  nmap
  wget
  tmux
  screen

  tldr # sometimes better docs

  # tools?
  just
  atool # uncompress or compress common formats with a common interface
  unzip
  pigz
  usql # decent universal db cli

  # dashboards
  htop
  btop

  # measuring
  hyperfine
  tokei
  stress
  ast-grep

  # nix stuff
  nix-tree # show dependencies and sizes of installed nixpkgs

  # working with html
  htmlq
  pandoc
]
