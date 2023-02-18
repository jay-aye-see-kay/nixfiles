{ pkgs, ... }:
{
  # WIP: collect all my "core" cli tools, describe then
  # install them on all hosts from here
  environment.systemPackages = with pkgs;
    let
      linuxOnlyPkgs = [
        lsof # list open files
        hdparm # query hard drive info
        pciutils # provides lspci
        parted # partition disks
      ];
      macOnlyPkgs = [
      ];
    in
    (if pkgs.stdenv.isLinux then linuxOnlyPkgs else macOnlyPkgs)
    ++ [
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
      progress # show progress of running processes
      pv # progress of pipes?
      duf # a "better" df
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
      git

      # dashboards
      htop
      btop
      powertop

      # measuring
      hyperfine
      tokei
      stress
    ];
}