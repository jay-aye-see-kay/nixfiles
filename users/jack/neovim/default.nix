{ config, pkgs, ... }:
{

  programs.neovim = {
    enable = true;
    withNodeJs = true;

    extraConfig = ''
      set termguicolors

      lua << EOF
      ${pkgs.lib.readFile ./init.lua}
      EOF
    '';

    plugins = with pkgs.unstable.vimPlugins; [
      { plugin = nvcode-color-schemes-vim; config = "colorscheme nvcode"; }
      nvim-treesitter
      nvim-treesitter-textobjects
      orgmode
      vim-nix
      nvim-lspconfig
      nvim-treesitter
      luasnip
    ];

    extraPackages = with pkgs.unstable; [
      stylua

      # language servers
      nodePackages.bash-language-server
      nodePackages.dockerfile-language-server-nodejs
      nodePackages.typescript
      nodePackages.typescript-language-server
      nodePackages.vim-language-server
      nodePackages.vscode-langservers-extracted
      pkgs.rnix-lsp
      rust-analyzer
      sumneko-lua-language-server

      # tree-sitter
      tree-sitter
      tree-sitter-grammars.tree-sitter-bash
      tree-sitter-grammars.tree-sitter-c
      tree-sitter-grammars.tree-sitter-fish
      tree-sitter-grammars.tree-sitter-javascript
      tree-sitter-grammars.tree-sitter-lua
      tree-sitter-grammars.tree-sitter-nix
      tree-sitter-grammars.tree-sitter-org-nvim
      tree-sitter-grammars.tree-sitter-python
      tree-sitter-grammars.tree-sitter-rust
      tree-sitter-grammars.tree-sitter-tsx
      tree-sitter-grammars.tree-sitter-typescript
      tree-sitter-grammars.tree-sitter-vim
    ];
  };

  xdg.configFile = with pkgs.unstable; {
    "nvim/parser/bash.so".source = "${tree-sitter.builtGrammars.tree-sitter-bash}/parser";
    "nvim/parser/c.so".source = "${tree-sitter.builtGrammars.tree-sitter-c}/parser";
    "nvim/parser/fish.so".source = "${tree-sitter.builtGrammars.tree-sitter-fish}/parser";
    "nvim/parser/javascript.so".source = "${tree-sitter.builtGrammars.tree-sitter-javascript}/parser";
    "nvim/parser/lua.so".source = "${tree-sitter.builtGrammars.tree-sitter-lua}/parser";
    "nvim/parser/nix.so".source = "${tree-sitter.builtGrammars.tree-sitter-nix}/parser";
    "nvim/parser/org.so".source = "${tree-sitter.builtGrammars.tree-sitter-org-nvim}/parser";
    "nvim/parser/python.so".source = "${tree-sitter.builtGrammars.tree-sitter-python}/parser";
    "nvim/parser/rust.so".source = "${tree-sitter.builtGrammars.tree-sitter-rust}/parser";
    "nvim/parser/tsx.so".source = "${tree-sitter.builtGrammars.tree-sitter-tsx}/parser";
    "nvim/parser/typescript.so".source = "${tree-sitter.builtGrammars.tree-sitter-typescript}/parser";
    "nvim/parser/vim.so".source = "${tree-sitter.builtGrammars.tree-sitter-vim}/parser";
  };
}
