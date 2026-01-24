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
        lazy-nvim # Plugin manager
        nvim-treesitter-textobjects # Treesitter textobjects extension
        (nvim-treesitter.withPlugins (p: with p; [
          bash
          c
          caddy
          css
          dockerfile
          fish
          gleam
          go
          gomod
          gosum
          gotmpl
          gowork
          graphql
          hcl
          html
          http
          hurl
          javascript
          json
          json
          json5
          jsonc
          lua
          markdown
          markdown_inline
          nix
          printf
          python
          rust
          sql
          templ
          toml
          tsx
          typescript
          vim
          vimdoc
          xml
          yaml
        ]))
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
      nodePackages."@tailwindcss/language-server"
      nodePackages.bash-language-server
      dockerfile-language-server
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
