{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.features.devtools;
in
{
  options.features.devtools = {
    enable = mkEnableOption "development tools including LSPs, formatters, debuggers, and language runtimes";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # NOTE: Plain neovim will be added here in Phase 5 after renaming mainNeovim to nnvim
      # For now, mainNeovim is still in users/jack/home.nix to avoid collision

      # Lazy.nvim plugin manager (installed via nix, referenced in lua config)
      vimPlugins.lazy-nvim

      # Language runtimes & tools
      nodejs
      yarn
      nodePackages_latest.pnpm
      go
      (python3.withPackages (ps: [ ps.ipykernel ]))
      just
      exercism

      # Kubernetes
      unstable.kubectl

      # LSPs
      godef
      gopls
      nodePackages."@tailwindcss/language-server"
      nodePackages.bash-language-server
      dockerfile-language-server-nodejs
      nodePackages.eslint_d
      pyright
      nodePackages.typescript
      nodePackages.typescript-language-server
      nodePackages.vim-language-server
      nodePackages.vscode-langservers-extracted
      nodePackages.yaml-language-server
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

      # Debuggers
      delve

      # Treesitter (CLI and parser generator)
      tree-sitter

      # Dictionaries (for spell checking)
      aspell
      aspellDicts.en
    ] ++ lib.optionals stdenv.isLinux [
      # Rust toolchain (only on Linux; use rustup on macOS due to Netskope issues)
      unstable.rustc
      unstable.rustfmt
      unstable.cargo-edit
      unstable.cargo
      unstable.clippy
      rust-analyzer

      # Ruby tools (primarily needed on Linux)
      rubyPackages.solargraph
    ];

    # Keep EDITOR pointing to nvim
    home.sessionVariables = {
      EDITOR = "nvim";
    };
  };
}
