{ config, lib, pkgs, pkgs-unstable, ... }:
with lib;
let
  cfg = config.modules.devtools;
in
{
  options.modules.devtools = {
    enable = mkEnableOption "development tools including LSPs, formatters, debuggers, and language runtimes";
  };

  config = mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = false;
      vimAlias = false;

      # Plugins managed by nix (stable, rarely change)
      plugins = with pkgs.vimPlugins; [
        # Plugin manager
        lazy-nvim

        # blink and treesitter have compiled deps, more reliable to install via nix
        blink-cmp
        blink-emoji-nvim
        nvim-treesitter-textobjects
        nvim-treesitter.withAllGrammars
      ];
    };

    home.packages = with pkgs; [
      # Language runtimes & tools
      nodejs
      yarn
      nodePackages_latest.pnpm
      go
      (python3.withPackages (ps: [ ps.ipykernel ]))
      just
      exercism

      # Kubernetes
      pkgs-unstable.kubectl

      # LSPs
      godef
      gopls
      tailwindcss-language-server
      bash-language-server
      dockerfile-language-server
      nodePackages.eslint_d
      pyright
      typescript
      typescript-language-server
      vim-language-server
      vscode-langservers-extracted
      yaml-language-server
      nixd
      lua-language-server
      ruff
      terraform-ls
      markdown-oxide
      templ
      shellcheck
      statix

      # Formatters
      black
      isort
      shfmt
      stylua
      nixpkgs-fmt

      # gotools includes a 'stress' binary that conflicts with the stress package (rm it)
      (gotools.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          rm -f $out/bin/stress
        '';
      }))

      # Debuggers
      delve

      # Dictionaries (for spell checking)
      aspell
      aspellDicts.en
    ] ++ lib.optionals stdenv.isLinux [
      # Rust toolchain (only on Linux; use rustup on macOS due to Netskope issues)
      pkgs-unstable.rustc
      pkgs-unstable.rustfmt
      pkgs-unstable.cargo-edit
      pkgs-unstable.cargo
      pkgs-unstable.clippy
      rust-analyzer

      # Ruby tools (primarily needed on Linux)
      rubyPackages.solargraph
    ];
  };
}
